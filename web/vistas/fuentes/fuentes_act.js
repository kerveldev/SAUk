import * as nauta from "/web/vistas/js/nauta.js";
let dUser  = nauta.getUser();
let _idReg = nauta.getId();
let campos = {};
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
    actualizarRegistro(_idReg);
  });

});
// :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::



/**
 * Carga los datos del registro por el idReg
 */
function cargarRegistro(_id){
  nauta.postData(
    'http://sau.test/api/usuarios/fuentes/FuenteId',
    {
      "nick"   : dUser.nick,
      "token"  : dUser.token,
      "id"     : _id,
      "campos" : ["Id_Fuente", "Fuente"]
    }).then(function(resp){
      let x = nauta.cBooleano(resp.status);
      if( x == true ){
        let reg = resp.data[0];
        // console.log(reg);

        // Se cargan los datos en los elementos
        $("#Fuente").val(reg.Fuente);

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
  let _fuente = $("#Fuente").val();

  // Validaciones

  // Fuente
  if (_fuente.length < 2) {
    vCampo = "Fuente";
    return false;
  }

  // Se asignan los valores a campos
  if (_fuente!=null&&_fuente!=undefined&&_fuente!="") {
    campos.Fuente = _fuente; 
  }

  // console.log(campos);

  return true;
}


/**
 * Actualiza el registro
 */
function actualizarRegistro(){
  let valido = preparaCampos();

  if (valido != false) {
    nauta.postData(
      'http://sau.test/api/usuarios/fuentes/actFuente',
      {
        "nick"  : dUser.nick,
        "token" : dUser.token,
        "id"    : _idReg,
        "datos" : campos
    }).then(function(data){
      let x = !!(data.status);
      if( x == true ){
        swal("Listo! Registro actualizado con éxito!", {
          icon: "success",
        });
        location.replace('fuentes_lst.html');
      }else{
        swal(`${data.msj}`, {
          title: 'Error en la acción!',
          icon: "error",
        });
      }
    }).catch(function(err){
      swal(`Erro en petición: ${err}`, {
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
  nauta.delId();
  window.location.replace('fuentes_lst.html');
}

