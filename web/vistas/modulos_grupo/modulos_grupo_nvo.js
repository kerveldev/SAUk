import * as nauta from "/web/vistas/js/nauta.js";
let dUser = nauta.getUser();
// Variables para la accion
let campos = {};
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
  let _grupo = $("#Grupo").val();

  // Validaciones

  // Grupo
  if (_grupo.length < 2) {
    vCampo = "Grupo";
    return false;
  }

  // Se asignan los valores a campos
  if (_grupo!=null&&_grupo!=undefined&&_grupo!="") {
    campos.Grupo = _grupo; 
  }

  // console.log(campos);

  return true;
}


/**
 * Guarda el nuevo registro
 */
function guardaNuevoRegistro(){
  let valido = preparaCampos();

  if (valido == true) {
    nauta.postData(
      'http://sau.test/api/usuarios/grupo/nvoGrupo',
      {
        "nick"  : dUser.nick,
        "token" : dUser.token,
        "datos" : campos
    }).then(function(data){
      let x = !!(data.status);
      if( x == true ){
        swal("Listo! Registro creado con éxito!", {
          icon: "success",
        });
        location.replace('modulos_grupo_lst.html');
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
  window.location.replace('modulos_grupo_lst.html');
}

