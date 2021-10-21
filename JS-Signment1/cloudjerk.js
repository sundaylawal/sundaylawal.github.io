// Java Signment1 
//Part A (BMI)

console.log(`PART A:`);

const LucasWEIGHT = 78; 
const LucasHEIGHT = 1.69; 
const  JohnWEIGHT = 92; 
const JohnHEIGHT = 1.95; 

let bmi = (weight, height) => {
    let calc = Math.round(weight/(height**2));
    return calc;
}

if (bmi(LucasWEIGHT,LucasHEIGHT) > bmi(JohnWEIGHT,JohnHEIGHT)) {
    console.log(`The BMi of John is ${bmi(JohnWEIGHT,JohnHEIGHT)}`);
    console.log(`The BMi of Lucas is ${bmi(LucasWEIGHT,LucasHEIGHT)}`);
    console.log(`Lucas' BMI is higher than John's BMI`);
} else {
    console.log(`The BMi of John is ${bmi(JohnWEIGHT,JohnHEIGHT)}`);
    console.log(`The BMi of Lucas is ${bmi(LucasWEIGHT,LucasHEIGHT)}`);
    console.log(`Lucas' BMI is higher than John's BMI!`);
}

console.log(null);

//Part B

console.log(`PART B:`);

const cels = 21;
const fahr = 70;

function celsToFahr(degCels) {
    let converted = Math.round((degCels*1.8) + 32);
    return converted;
}
function fahrToCels(degFahr) {
    let converted = Math.round((degFahr-32) * (5/9));
    return converted;
}

//  Temperature Converter

console.log(`${fahr} degrees Fahrenheit to ${fahrToCels(fahr)} degrees Celsius`);
console.log(`${cels} degrees Celsius to ${celsToFahr(cels)} degrees Fahrenheit`);

console.log(null);


// Part C


console.log(`PART C:`);

if (bmi(LucasWEIGHT,LucasHEIGHT) == bmi(JohnWEIGHT,JohnHEIGHT)) {
    console.log(`Lucas' BMI and John's BMI are equal at ${bmi(Lucas_WEIGHT,Lucas_HEIGHT)}`);
} else if (bmi(LucasWEIGHT,LucasHEIGHT) > bmi(JohnWEIGHT,JohnHEIGHT)) {
    console.log(`Lucas' BMI of ${bmi(LucasWEIGHT,LucasHEIGHT)} is higher than John's BMI of ${bmi(JohnWEIGHT,JohnHEIGHT)}`);
} else {
    console.log(`John's BMI of ${bmi(JohnWEIGHT,JohnHEIGHT)} is higher than Lucas' BMI of ${bmi(LucasWEIGHT,LucasHEIGHT)}`);
}

console.log(null);
console.log(`no further action necessary`);

const netsScore1 = [97, 112, 101];
const knicksScore1 = [109, 95, 123];

const netsScore2 = [97, 112, 101];
const knicksScore2 = [109, 95, 106];

let arrTotal = (arr) => {
    let total = 0;
    for(let i = 0; i < arr.length; i++) {
        total += arr[i];
    }
    return total;
}

function whoWon(arr1, arr2) {
    if (arrTotal(arr1) > arrTotal(arr2)) {
        console.log(`The Nets score are higher in the first set ${arrTotal(arr1)} points`);
    } else if (arrTotal(arr1) < arrTotal(arr2)) {
        console.log(`The Knicks score are higher in the first set ${arrTotal(arr2)} points`);
    } else {
        console.log(`Knicks and Nets are in a tie in the second set with each scoring ${arrTotal(arr1)} points`);
    }
}

whoWon(netsScore1,knicksScore1);
whoWon(netsScore2,knicksScore2);