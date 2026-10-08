# frozen_string_literal: true

require 'sinatra'
require 'json'
require_relative 'ciphers'

set :public_folder, File.join(__dir__, 'public')

MAGIC = 'CRY1'.b
MAGIC2 = 'CRY2'.b # file dikodekan ke huruf dulu (untuk cipher 26 huruf)
LETTER_CIPHERS = %w[vigenere autokey playfair affine hill enigma].freeze
NIB = 'ABCDEFGHIKLMNOPQ'.bytes.freeze # 16 huruf (tanpa J dan X) untuk 1 nibble

def to_letters(data)
  data.bytes.flat_map { |x| [NIB[x >> 4], NIB[x & 15]] }.pack('C*')
end

def from_letters(data)
  idx = NIB.each_with_index.to_h
  v = data.bytes.select { |c| idx.key?(c) }.map { |c| idx[c] } # huruf pengisi (X) dibuang
  raise ArgumentError, 'Kunci salah atau file rusak' if v.size.odd?

  v.each_slice(2).map { |h, l| (h << 4) | l }.pack('C*')
end

def b64(str)
  [str].pack('m0')
end

get '/' do
  erb :index
end

post '/api/process' do
  content_type :json
  begin
    cipher = params['cipher']
    fn = Ciphers::CIPHERS.fetch(cipher)[1]
    dec = params['mode'] == 'dec'
    key = params['key'].to_s
    up = params['file']
    from_file = params['source'] == 'file' && up.is_a?(Hash) && up[:tempfile]
    name = ''
    magic = MAGIC
    raw = from_file ? up[:tempfile].read.b : params['text'].to_s.b
    name = up[:filename].to_s if from_file

    if dec && from_file && [MAGIC, MAGIC2].include?(raw[0, 4])
      magic = raw[0, 4]
      n = raw[4, 2].unpack1('n')
      name = raw[6, n].dup.force_encoding('UTF-8')
      raw = raw[(6 + n)..]
    elsif dec && from_file
      name = ''
    elsif dec
      raw = params['text'].to_s.gsub(/\s+/, '').unpack1('m')
    elsif from_file && LETTER_CIPHERS.include?(cipher)
      magic = MAGIC2
    end

    inp = raw
    if dec
      out = fn.call(raw, key, true)
      out = from_letters(out) if magic == MAGIC2
      dl = out
      dl_name = name.empty? ? 'plainteks.bin' : name
    else
      out = fn.call(magic == MAGIC2 ? to_letters(raw) : raw, key, false)
      nb = name.b
      dl = magic + [nb.bytesize].pack('n') + nb + out
      dl_name = 'cipherteks.dat'
    end

    preview = out.dup.force_encoding('UTF-8').scrub("\uFFFD")[0, 2000]
    { ok: true, in_b64: b64(inp), out_b64: b64(out), preview: preview,
      dl_b64: b64(dl), dl_name: dl_name }.to_json
  rescue StandardError => e
    status 400
    { ok: false, error: e.message }.to_json
  end
end
