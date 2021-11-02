

function login(){

    let loginUserName = document.getElementById('usrLogin').value;
    let loginPassword = document.getElementById('pwdLogin').value;
    if(loginUserName === 'demoUser' && loginPassword === 'demoPass'){
        window.location = "tickets.html";
       }else{
        // login error
        document.getElementById("loginAlert").innerHTML = "Error!! Try again"; 
        document.getElementById('loginForm').reset();
    }
}





