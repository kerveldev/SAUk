import * as nauta from "/web/vistas/js/nauta.js";
let dUser = nauta.getUser();
// Variables para la accion
let _pat   = null;
let _mat   = null;
let _nom   = null;
let _unick = null;
let _upass = null;
let vCampo = null;

// ::::::::::::::: Se ejecuta al iniciar la carga de la pagina :::::::::::::::::::::
$(function () {
  // Se carga el menu lateral
  nauta.dMenu();
  
  //::::::::::::::::::: Barra de navegacion :::::::::::::::::::::
  nauta.dBarraNav();

  //:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

  // Cancelar
  $("#btnCancelar").click(function(){
    cancelar();
  });

  // Guardar btnGuardar
  $("#btnGuardar").click(function(){
    guardaNuevoRegistro();
  });

});
// :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


/**
 * Valida los campos para su almacenamiento.
 * @returns Retorna un objeto con los campos ya validados.
 */
function preparaCampos() {
  _pat   = $("#Paterno").val();
  _mat   = $("#Materno").val();
  _nom   = $("#Nombre").val();
  _unick = $("#Nick").val();
  _upass = $("#Pass").val();
  

  // Validaciones

  // Nombre
  if (_nom.length <= 2) {
    vCampo = "Nombre";
    return false;
  }
  // Nick
  if (_unick.length <= 4) {
    vCampo = "Nombre de usuario";
    return false;
  }
  // Pass
  if (_upass.length <= 4) {
    vCampo = "Contraseña";
    return false;
  }
  return true;
}


/**
 * Guarda el nuevo registro
 */
function guardaNuevoRegistro(){
  let valido = preparaCampos();

  if (valido == true) {
    nauta.postData(
      'http://sau.test/api/usuarios/navegante/nvoUsuario',
      {
        "nick"  : dUser.nick,
        "token" : dUser.token,
        "pat"   : _pat,
        "mat"   : _mat,
        "nom"   : _nom,
        "unick" : _unick,
        "upass" : _upass
    }).then(function(data){
      let x = !!(data.status);
      if( x == true ){
        swal("Listo! Registro creado con éxito!", {
          icon: "success",
        });
        location.replace('usuarios_lst.html');
      }else{
        swal(`${data.msj}`, {
          title: 'Error en la acción!',
          icon: "error",
        });
      }
    }).catch(function(err){
      swal(`Error en petición: ${err}`, {
        title: 'Error en la acción!',
        icon: "error",
      });
    });
  }else{
    swal(`Existe error en el campo ${vCampo}. Verifique los valores.`, {
      title: 'Error en la acción!',
      icon: "error",
    });
  }


}


// Se cancela la accion
function cancelar() {
  window.location.replace('usuarios_lst.html');
}

