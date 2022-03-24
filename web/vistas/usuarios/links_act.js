import * as nauta from "/web/vistas/js/nauta.js";
let dUser      = nauta.getUser();
let _idReg     = nauta.getId();
let _idUsuario = localStorage.getItem("idUsuario");
let _idNick    = localStorage.getItem("idNick");
let _idFnte    = localStorage.getItem("idFnte");
let _idFnteTit = localStorage.getItem("idFnteTit");
let campos     = {};
let vCampo     = null;

// ::::::::::::::: Se ejecuta al iniciar la carga de la pagina :::::::::::::::::::::
$(function () {
  // Se carga el menu lateral
  nauta.dMenu();

  // Cargar catalogos
  catalogoModulos();
  
  //::::::::::::::::::: Barra de navegacion :::::::::::::::::::::
  nauta.dBarraNav();

  //:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


  // Se verifica el idNick y se cargan los datos
  if (_idReg != null && _idReg != undefined) {
    cargarRegistro(_idReg);
    
  } else {
    swal("No se encontro el Nombre del Usuario.", {
      title : 'Error!',
      icon  : "error",
    });
  }
    
  // Se verifica el idNick y se cargan los datos
  if (_idUsuario == null || _idUsuario == undefined) {
    swal("No se encontro el Id del Usuario.", {
      title : 'Error!',
      icon  : "error",
    });
  }

  // Se verifica el idNick y se cargan los datos
  if (_idNick != null && _idNick != undefined) {
    $("#etUsuario").text(_idNick);    
    
  } else {
    swal("No se encontro el Nombre del Usuario.", {
      title : 'Error!',
      icon  : "error",
    });
  }

  // Se verifica el idFuente y se cargan los datos
  if (_idFnte == null || _idFnte == undefined) {
    swal("No se encontro el Id de la Fuente.", {
      title : 'Error!',
      icon  : "error",
    });
  }

  // Se verifica el titulo de la Fuente y se cargan los datos
  if (_idFnteTit != null && _idFnteTit != undefined) {
    $("#etModulo").text(_idFnteTit);
    
  } else {
    swal("No se encontro el Titulo de la Fuente.", {
      title : 'Error!',
      icon  : "error",
    });
  }

  $("#Principal").prop('checked',false);
  $("#Principal").val(-1);
  $("#Escritura").prop('checked',false);
  $("#Escritura").val(-1);


  // Se controlan los comportamientos de los checkbox
  $("#Principal").on("change",function(){
    if($(this).prop('checked')==true){
      $(this).val(1);
    }else{
      $(this).val(-1);
    }
  });

  $("#Escritura").on("change",function(){
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
    guardaNuevoRegistro(_idReg);
  });

});
// :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::



/**
 * Carga el catalogo de modulos
 */
function catalogoModulos(){
  nauta.postData(
    'http://sau.test/api/usuarios/modulo/lstModulos',
    {
      "nick"   : dUser.nick,
      "token"  : dUser.token,
      "campos" : ["Id_Modulo","Modulo"],
      "anexar" :[]
    }).then(function(resp){
      let x = nauta.cBooleano(resp.status);
      if( x == true ){
        let reg = resp.data;
        let opciones = "";
        if ( reg.length >= 1 ) {
          reg.forEach(valor => {
            opciones += `<option value="${valor.Id_Modulo}" >${valor.Modulo}</option>`
          });
          // Se agregan las opciones
          $("#Id_Modulo").html(opciones);
        }

      }else{
        console.log("No se pudo cargar el listado.");
      }
    }).catch(function(err){
      console.log(`Error en petición: ${err}`);
    });
}


/**
 * Carga los datos del registro por el idReg
 */
function cargarRegistro(_id){
  nauta.postData(
    'http://sau.test/api/usuarios/link/LinkId',
    {
      "nick"   : dUser.nick,
      "token"  : dUser.token,
      "id"     : _id,
      "campos" : ["Id_Link", "Id_Modulo", "Principal", "Escritura"]
    }).then(function(resp){
      let x = nauta.cBooleano(resp.status);
      if( x == true ){
        let reg = resp.data[0];
        // console.log(reg);

        // Se cargan los datos en los elementos
        $('#Id_Modulo').val(reg.Id_Modulo).trigger('change.select2');

        // Principal
        let _prin = nauta.cBooleano(reg.Principal);
        if ( _prin == true ) {
          $("#Principal").val(1);
          $("#Principal").prop("checked",true);
        } else {
          $("#Principal").val(-1);
          $("#Principal").prop("checked",false);
        }

        // Escritura
        let _esc = nauta.cBooleano(reg.Escritura);
        if ( _esc == true ) {
          $("#Escritura").val(1);
          $("#Escritura").prop("checked",true);
        } else {
          $("#Escritura").val(-1);
          $("#Escritura").prop("checked",false);
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
  let _idModulo  = $("#Id_Modulo").val();
  let _principal = $("#Principal").val();
  let _escritura = $("#Escritura").val();
  

  // Validaciones

  // Modulo
  if (_idModulo == undefined || _idModulo == null) {
    vCampo = "Modulo";
    return false;
  }

  // Se asignan los valores a campos
  if (_principal!=null&&_principal!=undefined&&_principal!="") {
    campos.Principal = _principal; 
  }
  if (_escritura!=null&&_escritura!=undefined&&_escritura!="") {
    campos.Escritura = _escritura; 
  }
  if (_idUsuario!=null&&_idUsuario!=undefined&&_idUsuario!="") {
    campos.Id_Usuario = _idUsuario; 
  }
  if (_idModulo!=null&&_idModulo!=undefined&&_idModulo!="") {
    campos.Id_Modulo = _idModulo; 
  }
  if (_idFnte!=null&&_idFnte!=undefined&&_idFnte!="") {
    campos.Id_Fuente = _idFnte; 
  }

  return true;
}



/**
 * Actualiza el registro
 */
function actualizarRegistro(){
  let valido = preparaCampos();

  if ( nauta.cBooleano(valido) == true) {
    nauta.postData(
      'http://sau.test/api/usuarios/link/actLink',
      {
        "nick"  : dUser.nick,
        "token" : dUser.token,
        "id"    : _idReg,
        "datos" : campos
    }).then(function(data){
      let x = !!(data.status);
      if( x == true ){
        swal("Listo! Registro creado con éxito!", {
          icon: "success",
        });
        location.replace('links_lst.html');
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
  nauta.delId();
  localStorage.setItem("idReg",_idUsuario);
  localStorage.removeItem("idUsuario");
  localStorage.removeItem("idFnte");
  localStorage.removeItem("idFnteTit");
  window.location.replace('links_lst.html');
}

