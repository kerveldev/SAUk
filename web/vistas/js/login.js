import { login } from "/web/vistas/js/nauta.js";

$(function () {
    $('#username').focus();

    $("#username").keypress(function(e) {
        if(e.which == 13 || e.which == 9) {
           $('#password').focus();
        }
    });
    $("#password").keypress(function(e) {
        if(e.which == 13 || e.which == 9) {
           $('#ingresar_btn').click();
        }
    });

    // Se escucha al boton ingresar
    $("#ingresar_btn").click(function (){
        const _n = $("#username").val();
        const _p = $("#password").val();

        const ing = login(_n,_p).then((data) => {
            // console.log(data);
            $("#respuesta").text(data.msj);
            localStorage.clear();
            localStorage.setItem("us", btoa( JSON.stringify(data.data)));
            window.location.replace(`viaje.php?nick=${data.data.nick}`);
        })
        .catch((err) => {
            // console.log(err);
            $("#respuesta").text(err.msj);
        });
    });
    
});