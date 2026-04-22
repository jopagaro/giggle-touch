const whisper = document.getElementById("whisper");
const pills = Array.from(document.querySelectorAll(".pill"));
const animeCard = document.querySelector(".anime-card");

let whisperTimer;

function showWhisper(message) {
  whisper.textContent = message;
  whisper.classList.add("visible");
  window.clearTimeout(whisperTimer);
  whisperTimer = window.setTimeout(() => {
    whisper.classList.remove("visible");
  }, 1800);
}

pills.forEach((pill) => {
  pill.addEventListener("mouseenter", () => {
    showWhisper(pill.dataset.whisper || "heh");
  });

  pill.addEventListener("focus", () => {
    showWhisper(pill.dataset.whisper || "heh");
  });
});

if (animeCard) {
  animeCard.addEventListener("mouseenter", () => {
    showWhisper("kyaa... your cursor has incredible chemistry");
  });
}
