import * as nauta from "/web/vistas/js/nauta.js";
let dUser  = nauta.getUser();
let _idReg = nauta.getId();
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
 * Obtiene el catalogo de grupos
 */
function cargarGrupos(){

  let opcGrupos = localStorage.getItem('opcGrupos');
  if ( opcGrupos.length >= 1 ) {
    $("#Grupo").append(opcGrupos);
  }

}



/**
 * Carga los datos del registro por el idReg
 */
function cargarRegistro(_id){
  nauta.postData(
    'http://sau.test/api/usuarios/modulo/ModuloId',
    {
      "nick"   : dUser.nick,
      "token"  : dUser.token,
      "id"     : _id,
      "campos" : ["Id_Modulo","Modulo","Ruta", "Grupo"]
    }).then(function(resp){
      let x = nauta.cBooleano(resp.status);
      if( x == true ){
        let reg = resp.data[0];
        // console.log(reg);

        // Se cargan los datos en los elementos
        $("#Modulo").val(reg.Modulo);
        $("#Grupo").val(reg.Grupo);
        // $("#Grupo option[value="+ reg.Grupo.toString() +"]").attr("selected",true);
        $("#Ruta").val(reg.Ruta.toString());

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
  if (_grupo.length == null) {
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
 * Actualiza el registro
 */
function actualizarRegistro(){
  let valido = preparaCampos();

  if (valido != false) {
    nauta.postData(
      'http://sau.test/api/usuarios/modulo/actModulo',
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
        location.replace('modulos_lst.html');
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
  window.location.replace('modulos_lst.html');
}

