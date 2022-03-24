import * as nauta from "/web/vistas/js/nauta.js";
let dUser  = nauta.getUser();
let _idReg = nauta.getId();
let vCampo = null;

// ::::::::::::::: Se ejecuta al iniciar la carga de la pagina :::::::::::::::::::::
$(function () {
  // Se carga el menu lateral
  nauta.dMenu();

  // Se cargan los catalogos
  cargarNiveles();

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

  // Se controlan los comportamientos de los checkbox
  $("#Activo").on("change",function(){
    if($(this).prop('checked')==true){
      $(this).val(1);
    }else{
      $(this).val(-1);
    }
  });

  $("#EnLinea").on("change",function(){
    if($(this).prop('checked')==true){
      $(this).val(1);
    }else{
      $(this).val(-1);
    }
  });
  

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
 * Obtiene el listado de los niveles para cargarlos
 */
function cargarNiveles(){
  let opciones = localStorage.getItem('opcNiveles');
  if ( opciones.length >= 1 ) {
    $("#Nivel_selc").append(opciones);
  }
}



/**
 * Carga los datos del registro por el idReg
 */
function cargarRegistro(_id){
  nauta.postData(
    'http://sau.test/api/usuarios/navegante/UsuarioId',
    {
      "nick"   : dUser.nick,
      "token"  : dUser.token,
      "id"     : _id,
      "campos" : ["Paterno", "Materno", "Nombre", "Nick", "Nivel", "Activo", "EnLinea"]
    }).then(function(resp){
      let x = nauta.cBooleano(resp.status);
      if( x == true ){
        let reg = resp.data[0];
        // console.log(reg);

        // Se cargan los datos en los elementos
        $("#Paterno").val(reg.Paterno);
        $("#Materno").val(reg.Materno);
        $("#Nombre").val(reg.Nombre);
        $("#Nick").val(reg.Nick);

        // Nivel
        $("#Nivel_selc").val(reg.Nivel);

        // Activo
        let _act = nauta.cBooleano(reg.Activo);
        if ( _act == true ) {
          $("#Activo").val(1);
          $("#Activo").prop("checked",true);
        } else {
          $("#Activo").val(-1);
          $("#Activo").prop("checked",false);
        }

        // EnLinea
        let _enl = nauta.cBooleano(reg.EnLinea);
        if ( _enl == true ) {
          $("#EnLinea").val(1);
          $("#EnLinea").prop("checked",true);
        } else {
          $("#EnLinea").val(-1);
          $("#EnLinea").prop("checked",false);
        }


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
  let _pat   = $("#Paterno").val();
  let _mat   = $("#Materno").val();
  let _nom   = $("#Nombre").val();
  let _unick = $("#Nick").val();
  let _nivel = $("#Nivel_selc").val();
  let _actvo = $("#Activo").val();
  let _linea = $("#EnLinea").val();
  

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

  // Campos
  const _camp = {
    "Paterno" : _pat,
    "Materno" : _mat,
    "Nombre"  : _nom,
    "Nick"    : _unick,
    "Nivel"   : _nivel,
    "Activo"  : _actvo,
    "EnLinea" : _linea,
  };


  return _camp;
}


/**
 * Actualiza el registro
 */
function actualizarRegistro(){
  let campos = preparaCampos();

  if (campos != false) {
    nauta.postData(
      'http://sau.test/api/usuarios/navegante/actUsuario',
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
        location.replace('usuarios_lst.html');
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
  nauta.limpiarCache();
  window.location.replace('usuarios_lst.html');
}

