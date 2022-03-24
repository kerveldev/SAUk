import * as nauta from "/web/vistas/js/nauta.js";
let dUser = nauta.getUser();
// Variables para la accion
let campos = {};
let vCampo = null;

// ::::::::::::::: Se ejecuta al iniciar la carga de la pagina :::::::::::::::::::::
$(function () {

  // Se carga el menu lateral
  nauta.dMenu();

  // Cargar catalogos
  cargarGrupos();
  
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
 * Obtiene el listado de los proveedores para cargarlos
 */
 function cargarGrupos(){
  nauta.postData(
    'http://sau.test/api/usuarios/grupo/lstGrupos',
    {
      "nick"   : dUser.nick,
      "token"  : dUser.token,
      "campos" : ["Id_Grupo", "Grupo"]
    }).then(function(resp){
      let x = nauta.cBooleano(resp.status);
      if( x == true ){
        let reg = resp.data;
        // console.log(reg);
        let opciones = "";
        if ( reg.length >= 1 ) {
          reg.forEach(valor => {
            opciones += `<option value="${valor.Id_Grupo}">${valor.Grupo}</option>`
          });
          $("#Grupo").append(opciones);
        }

      }else{
        console.log("No se pudo cargar el listado de tipos.");
      }
    }).catch(function(err){
      console.log(`Error en petición: ${err}`);
    });
}


/**
 * Valida los campos para su almacenamiento.
 * @returns Retorna un objeto con los campos ya validados.
 */
function preparaCampos() {
  let _modulo = $("#Modulo").val();
  let _grupo  = $("#Grupo").val();
  let _ruta   = $("#Ruta").val();

  // Validaciones

  // Modulo
  if (_modulo.length < 2) {
    vCampo = "Modulo";
    return false;
  }
  // Grupo
  if (_grupo.length < 2) {
    vCampo = "Grupo";
    return false;
  }
  // Ruta
  if (_ruta.length < 2) {
    vCampo = "Ruta";
    return false;
  }

  // Se asignan los valores a campos
  if (_modulo!=null&&_modulo!=undefined&&_modulo!="") {
    campos.Modulo = _modulo; 
  }
  // Se asignan los valores a campos
  if (_grupo!=null&&_grupo!=undefined&&_grupo!="") {
    campos.Grupo = _grupo; 
  }
  // Se asignan los valores a campos
  if (_ruta!=null&&_ruta!=undefined&&_ruta!="") {
    campos.Ruta = _ruta; 
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
      'http://sau.test/api/usuarios/modulo/nvoModulo',
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
        location.replace('modulos_lst.html');
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
  window.location.replace('modulos_lst.html');
}

