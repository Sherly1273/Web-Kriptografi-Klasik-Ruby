const $ = (id) => document.getElementById(id);
let last = null,
  cipher = document.querySelector(".tile").dataset.k,
  src = "text";
const H = {
  vigenere: ["Kata, huruf A-Z saja. Contoh: SECRET", "Teks"],
  autokey: ["Kata, huruf A-Z saja. Contoh: KEY", "Teks"],
  extended: ["Teks bebas (dibaca per byte). Contoh: rahasia", "Teks atau file"],
  playfair: ["Kata, huruf A-Z. J digabung ke I. Contoh: MONARCHY", "Teks"],
  affine: ["Dua angka a,b dengan a koprima ke 26. Contoh: 5,8", "Teks"],
  hill: ["Angka matriks n x n. Contoh 2x2: 3 3 2 5", "Teks"],
  enigma: [
    "3 huruf posisi rotor, opsional plugboard. Contoh: ABC atau ABC AB CD",
    "Teks",
  ],
  super: [
    "Teks bebas; juga menentukan urutan kolom transposisi",
    "Teks atau file",
  ],
};
function hint() {
  $("kh").textContent = H[cipher][0];
  $("key").placeholder = H[cipher][0].split(". ").pop();
  $("th").textContent =
    H[cipher][1] == "Teks" ? "(26 huruf: non-huruf dibuang)" : "";
}
document.querySelectorAll(".tile").forEach(
  (t) =>
    (t.onclick = () => {
      document
        .querySelectorAll(".tile")
        .forEach((x) => x.classList.remove("on"));
      t.classList.add("on");
      cipher = t.dataset.k;
      hint();
    }),
);
function mode(m) {
  src = m;
  $("bt").classList.toggle("on", m == "text");
  $("bf").classList.toggle("on", m == "file");
  $("tr").style.display = m == "text" ? "block" : "none";
  $("drop").style.display = m == "file" ? "block" : "none";
}
$("bt").onclick = () => mode("text");
$("bf").onclick = () => mode("file");
const dr = $("drop");
dr.onclick = () => $("file").click();
$("file").onchange = () => {
  $("fn").textContent =
    $("file").files[0]?.name || "Pilih file atau seret ke sini";
};
dr.ondragover = (e) => {
  e.preventDefault();
  dr.classList.add("over");
};
dr.ondragleave = () => dr.classList.remove("over");
dr.ondrop = (e) => {
  e.preventDefault();
  dr.classList.remove("over");
  $("file").files = e.dataTransfer.files;
  $("file").onchange();
};
async function go(m) {
  const er = $("err");
  er.style.display = "none";
  if (src == "file" && !$("file").files[0]) {
    er.textContent = "Pilih file terlebih dahulu.";
    er.style.display = "block";
    return;
  }
  const fd = new FormData();
  fd.append("mode", m);
  fd.append("cipher", cipher);
  fd.append("key", $("key").value);
  fd.append("source", src);
  fd.append("text", $("text").value);
  if ($("file").files[0]) fd.append("file", $("file").files[0]);
  const b = [$("e"), $("d")];
  b.forEach((x) => (x.disabled = true));
  try {
    const r = await fetch("/api/process", { method: "POST", body: fd }),
      j = await r.json();
    if (!j.ok) {
      er.textContent = j.error;
      er.style.display = "block";
      return;
    }
    last = j;
    $("inb").textContent = j.in_b64;
    $("outb").textContent = j.out_b64;
    $("prev").textContent = j.preview;
    document.querySelectorAll("pre").forEach((p) => p.classList.remove("full"));
    $("res").style.display = "block";
    $("dl").style.display = "inline-block";
    $("res").scrollIntoView({ behavior: "smooth", block: "nearest" });
  } catch (x) {
    er.textContent = "Tidak dapat menghubungi server.";
    er.style.display = "block";
  } finally {
    b.forEach((x) => (x.disabled = false));
  }
}
$("e").onclick = () => go("enc");
$("d").onclick = () => go("dec");
document.querySelectorAll("[data-c]").forEach(
  (b) =>
    (b.onclick = async () => {
      await navigator.clipboard.writeText($(b.dataset.c).textContent);
      const t = b.textContent;
      b.textContent = "Tersalin";
      setTimeout(() => (b.textContent = t), 1200);
    }),
);
document.querySelectorAll("[data-x]").forEach(
  (b) =>
    (b.onclick = () => {
      const p = $(b.dataset.x);
      p.classList.toggle("full");
      b.textContent = p.classList.contains("full")
        ? "Ciutkan"
        : "Tampilkan semua";
    }),
);
$("dl").onclick = () => {
  const u = Uint8Array.from(atob(last.dl_b64), (c) => c.charCodeAt(0)),
    a = document.createElement("a");
  a.href = URL.createObjectURL(new Blob([u]));
  a.download = last.dl_name;
  a.click();
};
hint();
