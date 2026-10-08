# frozen_string_literal: true

require 'matrix'

# Semua cipher bekerja pada byte (String biner) dan mengembalikan String biner.
# Cipher "26 huruf" hanya memproses huruf A-Z; karakter lain dibuang.
module Ciphers
  module_function

  ROTORS = [ # [kabel, notch] Enigma I
    ['EKMFLGDQVZNTOWYHXUSPAIBRCJ', 'Q'],
    ['AJDKSIRUXBLHWTMCQGZNPYFVOE', 'E'],
    ['BDFHJLCPRTXVZNYEIWGAKMUSQO', 'V']
  ].freeze
  REFLECTOR_B = 'YRUHQSLDPXNGOKMIEBFZCWVJAT'

  # --- fungsi bantu ---------------------------------------------------------

  def letters(bytes)
    bytes.map { |b| b.between?(97, 122) ? b - 32 : b }
         .select { |b| b.between?(65, 90) }
         .map { |b| b - 65 }
  end

  def to_bytes(values)
    values.map { |x| x + 65 }.pack('C*')
  end

  def key_letters(key)
    k = letters(key.bytes)
    raise ArgumentError, 'Kunci harus mengandung huruf A-Z' if k.empty?

    k
  end

  # --- cipher ---------------------------------------------------------------

  def vigenere(data, key, dec)
    p = letters(data.bytes)
    k = key_letters(key)
    s = dec ? -1 : 1
    to_bytes(p.each_with_index.map { |c, i| (c + s * k[i % k.size]) % 26 })
  end

  def autokey(data, key, dec)
    p = letters(data.bytes)
    k = key_letters(key)
    unless dec
      ks = k + p
      return to_bytes(p.each_with_index.map { |c, i| (c + ks[i]) % 26 })
    end

    ks = k.dup
    out = []
    p.each_with_index do |c, i|
      x = (c - ks[i]) % 26
      out << x
      ks << x
    end
    to_bytes(out)
  end

  def extended(data, key, dec)
    kb = key.bytes
    raise ArgumentError, 'Kunci tidak boleh kosong' if kb.empty?

    s = dec ? -1 : 1
    data.bytes.each_with_index.map { |b, i| (b + s * kb[i % kb.size]) % 256 }.pack('C*')
  end

  def playfair(data, key, dec)
    sq = []
    (key_letters(key) + (0..25).to_a).each do |c|
      c = 8 if c == 9 # J digabung ke I
      sq << c unless sq.include?(c)
    end
    pos = {}
    sq.each_with_index { |c, i| pos[c] = i.divmod(5) }
    p = letters(data.bytes).map { |c| c == 9 ? 8 : c }

    if dec
      raise ArgumentError, 'Panjang cipherteks Playfair harus genap' if p.size.odd?
    else
      out = []
      i = 0
      while i < p.size
        a = p[i]
        b = i + 1 < p.size ? p[i + 1] : 23 # huruf pengisi X
        if a == b
          b = 23
          i += 1
        else
          i += 2
        end
        out << a << b
      end
      p = out
    end

    s = dec ? -1 : 1
    res = []
    p.each_slice(2) do |x, y|
      r1, c1 = pos[x]
      r2, c2 = pos[y]
      if r1 == r2
        c1 = (c1 + s) % 5
        c2 = (c2 + s) % 5
      elsif c1 == c2
        r1 = (r1 + s) % 5
        r2 = (r2 + s) % 5
      else
        c1, c2 = c2, c1
      end
      res << sq[r1 * 5 + c1] << sq[r2 * 5 + c2]
    end
    to_bytes(res)
  end

  def affine(data, key, dec)
    parts = key.delete(' ').split(',')
    raise ArgumentError, 'Kunci Affine harus berformat a,b' unless parts.size == 2

    a, b = parts.map { |x| Integer(x, 10) }
    raise ArgumentError, 'a harus koprima dengan 26' unless a.gcd(26) == 1

    ai = (1..25).find { |x| (a * x) % 26 == 1 }
    to_bytes(letters(data.bytes).map { |c| dec ? (ai * (c - b)) % 26 : (a * c + b) % 26 })
  rescue ArgumentError => e
    raise ArgumentError, 'Kunci Affine harus berformat a,b' if e.message.start_with?('invalid value')

    raise
  end

  def hill(data, key, dec)
    nums = key.tr(',', ' ').split.map { |x| Integer(x, 10) }
    n = Integer.sqrt(nums.size)
    unless n >= 2 && n * n == nums.size
      raise ArgumentError, 'Jumlah angka kunci harus kuadrat sempurna (4, 9, ...)'
    end

    m = Matrix.build(n) { |r, c| nums[r * n + c] }
    det = m.determinant % 26
    raise ArgumentError, 'Determinan kunci tidak punya invers mod 26' unless det.gcd(26) == 1

    if dec
      di = (1..25).find { |x| (det * x) % 26 == 1 }
      m = Matrix.build(n) { |r, c| ((-1)**(r + c) * m.first_minor(c, r).determinant * di) % 26 }
    end

    p = letters(data.bytes)
    raise ArgumentError, "Panjang cipherteks harus kelipatan #{n}" if dec && (p.size % n).positive?

    p += [23] * ((-p.size) % n)
    out = []
    p.each_slice(n) { |blk| out.concat((m * Vector.elements(blk)).to_a.map { |x| x % 26 }) }
    to_bytes(out)
  end

  # Enigma I (rotor I-II-III, reflektor B). Kunci: 'ABC' atau 'ABC AB CD'
  # (posisi awal rotor kiri-tengah-kanan, lalu pasangan plugboard).
  def enigma(data, key, _dec)
    parts = key.upcase.split
    unless parts.any? && parts[0].match?(/\A[A-Z]{3}\z/)
      raise ArgumentError, 'Kunci Enigma: 3 huruf posisi rotor, mis. ABC'
    end

    pos = parts[0].bytes.map { |c| c - 65 }
    plug = (0..25).to_a
    parts[1..].each do |pr|
      unless pr.match?(/\A[A-Z]{2}\z/) && pr[0] != pr[1]
        raise ArgumentError, 'Plugboard berupa pasangan 2 huruf berbeda, mis. AB CD'
      end

      a = pr.getbyte(0) - 65
      b = pr.getbyte(1) - 65
      raise ArgumentError, 'Huruf plugboard tidak boleh dipakai dua kali' if plug[a] != a || plug[b] != b

      plug[a] = b
      plug[b] = a
    end
    fwd = ROTORS.map { |w, _| w.bytes.map { |c| c - 65 } }
    inv = ROTORS.map { |w, _| (0..25).map { |i| w.index((65 + i).chr) } }
    ref = REFLECTOR_B.bytes.map { |c| c - 65 }
    notch = ROTORS.map { |_, n| n.ord - 65 }

    out = letters(data.bytes).map do |c|
      if pos[1] == notch[1] # double-stepping
        pos[0] = (pos[0] + 1) % 26
        pos[1] = (pos[1] + 1) % 26
      elsif pos[2] == notch[2]
        pos[1] = (pos[1] + 1) % 26
      end
      pos[2] = (pos[2] + 1) % 26
      c = plug[c]
      [2, 1, 0].each { |i| c = (fwd[i][(c + pos[i]) % 26] - pos[i]) % 26 }
      c = ref[c]
      [0, 1, 2].each { |i| c = (inv[i][(c + pos[i]) % 26] - pos[i]) % 26 }
      plug[c]
    end
    to_bytes(out) # enkripsi dan dekripsi sama (resiprokal)
  end

  # Transposisi kolom tanpa padding: urutan kolom ditentukan oleh kunci.
  def permutation(n, kb)
    cols = kb.size
    order = (0...cols).sort_by { |i| [kb[i], i] }
    order.flat_map { |c| (c...n).step(cols).to_a }
  end

  def super_enc(data, key, dec)
    kb = key.bytes
    raise ArgumentError, 'Kunci tidak boleh kosong' if kb.empty?

    unless dec
      e = extended(data, key, false).bytes
      return permutation(e.size, kb).map { |i| e[i] }.pack('C*')
    end

    d = data.bytes
    t = Array.new(d.size)
    permutation(d.size, kb).each_with_index { |i, j| t[i] = d[j] }
    extended(t.pack('C*'), key, true)
  end

  CIPHERS = {
    'vigenere' => ['Vigenere Standard (26 huruf)', method(:vigenere)],
    'autokey' => ['Auto-Key Vigenere (26 huruf)', method(:autokey)],
    'extended' => ['Extended Vigenere (256 ASCII)', method(:extended)],
    'playfair' => ['Playfair (26 huruf)', method(:playfair)],
    'affine' => ['Affine (26 huruf)', method(:affine)],
    'hill' => ['Hill (26 huruf)', method(:hill)],
    'enigma' => ['Enigma (26 huruf)', method(:enigma)],
    'super' => ['Super Enkripsi (Ext. Vigenere + Transposisi Kolom)', method(:super_enc)]
  }.freeze
end
