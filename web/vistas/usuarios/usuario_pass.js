import * as nauta from "/web/vistas/js/nauta.js";
let dUser  = nauta.getUser();
let _idReg = nauta.getId();
// Variables para la accion
let _upass = null;
let vCampo = null;

// ::::::::::::::: Se ejecuta al iniciar la carga de la pagina :::::::::::::::::::::
$(function () {
  // Se carga el menu lateral
  nauta.dMenu();
  
  //::::::::::::::::::: Barra de navegacion :::::::::::::::::::::
  nauta.dBarraNav();

  //:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

  // Se verifica el idReg y se cargan los datos
  if (_idReg != null && _idReg != undefined) {
    $("#nomUs").text(_idReg);
    cargarRegistro(_idReg);
  } else {
    swal("No se encontro el Id del Registro.", {
      title : 'Error!',
      icon  : "error",
    });
  }

  // Cancelar
  $("#btnCancelar").click(function(){
    cancelar();
  });

  // Guardar btnGuardar
  $("#btnGuardar").click(function(){
    actualizaPass();
  });

});
// :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


/**
 * Carga los datos del registro por el idReg
 */
function cargarRegistro(_id){
  nauta.postData(
    'http://sau.test/api/usuarios/logger/verPass',
    {
      "nick"   : dUser.nick,
      "token"  : dUser.token,
      "uNick"  : _id
    }).then(function(resp){
      let x = nauta.cBooleano(resp.status);
      if( x == true ){
        let reg = resp.data;
        // console.log(reg);

        // Se cargan los datos en los elementos
        $("#aPass").val(reg);

      }else{
        swal("No se pudo cargar la informacion del registro.", {
          title : 'Error!',
          icon  : "error",
        });
      }
    }).catch(function(err){
      swal(`Error en petición: ${err}`, {
        title : 'Error en la acción!',
        icon  : "error",
      });
    });

}



/**
 * Valida los campos para su almacenamiento.
 * @returns Retorna un objeto con los campos ya validados.
 */
function preparaCampos() {
  _upass = $("#nPass").val();

  // Validaciones

  // Pass
  if (_upass.length < 4) {
    vCampo = "Contraseña";
    return false;
  }
  return true;
}


/**
 * Guarda el nuevo registro
 */
function actualizaPass(){
  let valido = preparaCampos();

  if (valido == true) {
    nauta.postData(
      'http://sau.test/api/usuarios/logger/cambioPass',
      {
        "nick"    : dUser.nick,
        "token"   : dUser.token,
        "uNick"   : _idReg,
        "nvoPass" : _upass
    }).then(function(data){
      let x = !!(data.status);
      if( x == true ){
        swal("Listo! Contraseña actulizada con éxito!", {
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
  nauta.limpiarCache();
  window.location.replace('usuarios_lst.html');
}

