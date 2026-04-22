const whisper = document.getElementById("whisper");
const pills = Array.from(document.querySelectorAll(".pill"));
const heroImage = document.querySelector(".hero-image");

let whisperTimer;

function showWhisper(message) {
  if (!whisper) return;
  whisper.textContent = message;
  whisper.classList.add("visible");
  window.clearTimeout(whisperTimer);
  whisperTimer = window.setTimeout(() => {
    whisper.classList.remove("visible");
  }, 1800);
}

pills.forEach((pill) => {
  pill.addEventListener("mouseenter", () => {
    showWhisper(pill.dataset.whisper || "hehe");
  });

  pill.addEventListener("focus", () => {
    showWhisper(pill.dataset.whisper || "hehe");
  });
});

if (heroImage) {
  heroImage.addEventListener("mouseenter", () => {
    showWhisper("the giggle queen has entered the menu bar");
  });
}
