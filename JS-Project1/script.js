function randNum() {
  return Math.floor(Math.random() * 100) + 1;
}

let score = 10;
let guessCount = 1;
let guesses = document.querySelector('.guesses');
let answer = document.querySelector('.answer');
let lowOrHi = document.querySelector('.lowOrHi');
let btn = document.querySelector('.submit');
let userInput = document.querySelector('#userGuess');
let scoreCount = document.querySelector('.score');
let highScore = document.querySelector('.best');
let resetButton;
let highest = 0;

let number = randNum();
answer.textContent = '?';

let tally = (maxScore, count) => {
return maxScore - count;
}

scoreCount.textContent = 'Score: ' + score;

let best = (newScore) => {
if (newScore > highest) {
  return highScore.textContent = 'Best: ' + newScore;
}else {
  return highScore.textContent = 'Best: ' + highest;
}
}


function guessingGame() {
console.log(number);
  let x = userInput.value;
  
  const message = document.querySelector(".errors");
  message.innerHTML = "";
  try { 
    if(x == "")  throw "empty";
    if(isNaN(x)) throw "NO NUMBER HAS BEEN ENTERED!";
    // x = Number(x);
  }
  catch(err) {
    message.textContent = "TRY AGAIN, " + err;
  }
  

  //  guesses.textContent = 'Guesses: ';

  
  if (Number(x) ==  number) {
    answer.textContent = number;
    guessCount++;
    guesses.textContent += x + ', ';
    lowOrHi.textContent = 'YOU WIN';
    console.log(scoreCount.textContent = 'Score: ' + tally(score, guessCount));
    best(tally(score, guessCount)); //intializing best score
    gameOver();
  }else if(guessCount === 10){
    answer.textContent = number;
    scoreCount.textContent = 'Score: 0';
    guesses.textContent += x + ', ';
    lowOrHi.textContent = 'YOU LOSE';
    gameOver();
  }else if(x === '') {
    message.textContent = 'TRY AGAIN, NO NUMBER HAS BEEN ENTERED!';
  }else {
    if (number > x) {
      guessCount++;
      guesses.textContent += x + ', ';
      lowOrHi.textContent = 'YOUR GUESS IS TOO LOW';
      scoreCount.textContent = 'Score: ' + tally(score, guessCount);
    }else if ((number < x)){
      guessCount++;
      guesses.textContent += x + ', ';
      lowOrHi.textContent = 'YOUR GUESS IS TOO HIGH';
      scoreCount.textContent = 'Score: ' + tally(score, guessCount);
    }
  }
  
  userInput.value = '';
}

btn.addEventListener('click', guessingGame);


function gameOver() {
userInput.disabled = true;
btn.disabled = true;

resetButton = document.createElement('button');
resetButton.textContent = 'Play Again?';
resetButton.style.position = 'relative';
resetButton.style.backgroundColor = '#ff7518';
resetButton.style.color = 'black';
resetButton.style.top = '30px';
resetButton.style.left = '30px';
resetButton.style.fontSize = '18px';
resetButton.style.fontWeight = 'bold';
resetButton.style.borderRadius = '30%';
resetButton.style.padding = '1%';
document.body.appendChild(resetButton);
resetButton.addEventListener('click', reset);
}
function reset() {
guessCount = 1;
let resetPar = document.querySelectorAll('.resultPar p');
for(let i = 0 ; i < resetPar.length ; i++) {
  resetPar[i].textContent = '';
}
resetButton.parentNode.removeChild(resetButton);
userInput.disabled = false;
btn.disabled = false;
userInput.value = '';
number = randNum();
answer.textContent = number;
scoreCount.textContent = 'Score: ' + tally(score, guessCount);
answer.textContent = '?';
}