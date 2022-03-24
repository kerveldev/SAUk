import * as nauta from "/web/vistas/js/nauta.js";
let dUser   = nauta.getUser();
let _idReg  = nauta.getId();
let _idNick = localStorage.getItem("idNick");
let tabla   = null;


// ::::::::::::::: Se ejecuta al iniciar la carga de la pagina :::::::::::::::::::::
$(function () {
  // Se carga el menu lateral
  nauta.dMenu();

  // Cargar catalogos
  catalogoFuentes();
  
  //::::::::::::::::::: Barra de navegacion :::::::::::::::::::::
  nauta.dBarraNav();

  //:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    
  // Se verifica el idNick y se cargan los datos
  if (_idNick != null && _idNick != undefined) {
    $("#etUsuario").text(_idNick);    
    
  } else {
    swal("No se encontro el Id del Usuario.", {
      title : 'Error!',
      icon  : "error",
    });
  }
  

  // Buscar
  $("#btnBuscar").click(function(){
    const _idFnte = $("#Id_Fuente option:selected").val();
    buscarFuente(_idReg, _idFnte);
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
 * Carga el catalogo de fuentes
 */
function catalogoFuentes(){
  nauta.postData(
    'http://sau.test/api/usuarios/fuentes/lstFuentes',
    {
      "nick"   : dUser.nick,
      "token"  : dUser.token,
      "campos" : ["Id_Fuente","Fuente"]
    }).then(function(resp){
      let x = nauta.cBooleano(resp.status);
      if( x == true ){
        let reg = resp.data;
        let opciones = "";
        if ( reg.length >= 1 ) {
          reg.forEach(valor => {
            opciones += `<option value="${valor.Id_Fuente}">${valor.Fuente}</option>`
          });
          // Se agregan las opciones
          $("#Id_Fuente").html(opciones);
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
 * y el Id Fuente
 */
function buscarFuente(_id, _idFte){
  nauta.postData(
    'http://sau.test/api/usuarios/link/linksUsuario',
    {
      "nick"   : dUser.nick,
      "token"  : dUser.token,
      "id"     : _id,
      "idfte"  : _idFte,
      "campos" : ["Id_Link","Principal","Escritura"],
      "anexar" : [ 
                  { 
                      "tabla"   : "modulos", 
                      "id"      : "Id_Modulo", 
                      "id_join" : "Id_Modulo", 
                      "campos"  : [ "Modulo" ] 
                  }
                ]
    }).then(function(resp){
      let x = nauta.cBooleano(resp.status);
      if( x == true ){
        
        // Se convierten los 1 / 0 en SI / NO
        if (resp.data!=null && resp.data!=undefined) {
          
          resp.data.forEach(reg => {
            let cValor    = "";
            cValor        = nauta.cBooleano(reg.Principal);
            reg.Principal = cValor==true?"Si":"no";
            cValor        = nauta.cBooleano(reg.Escritura);
            reg.Escritura = cValor==true?"Si":"no";
          });

          tabla = nauta.dibujarTabla("regs-tabla", resp.data, ["Id", "Principal", "Lectura", "Modulo"]);

          // >>>>>>>>>>>>> INICIO controladores para los botones de accion <<<<<<<<<<<<<<<<<
      
          // Nuevo
          $(".btnNvoDT").click(function() {
            nuevo();
          });

          // Actualizar
          $(".btnAct").click( function(e){
            let r = tabla.row( '.selected' ).data();
            if (r!=undefined || r!=null) {
              let id = tabla.row('.selected').data()[0];
              actualizar(id.toString());
            } else {
              noRegSelec();
            }
          });

          // Eliminar
          $(".btn-warning-cancel").click( function(f){
            let r = tabla.row( '.selected' ).data();
            if (r!=undefined || r!=null) {
              let id = tabla.row('.selected').data()[0];
              eliminar(id,tabla);
            } else {
              noRegSelec();
            }
          });
          // >>>>>>>>>>>>> FIN controladores para los botones de accion <<<<<<<<<<<<<<<<<
        }else{
          // Se manda una tabla vacia
          const tVacia = [{"Id" : null, "Principal" : null, "Lectura" : null, "Modulo" : null}]
          
          tabla = nauta.dibujarTabla("regs-tabla",tVacia, ["Id", "Principal", "Lectura", "Modulo"]);
          
          if (tabla!=undefined || tabla!=null) {
            tabla.clear().draw();
          }
          
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



// Abre la pagina para nuevo registro _idReg
function nuevo() {
  localStorage.setItem("idFnte",$("#Id_Fuente option:selected").val());
  localStorage.setItem("idFnteTit",$("#Id_Fuente option:selected").text());
  window.location.replace('links_nvo.html');
}


// Abre la pagina para actualizar registro
function actualizar(_id) {
  localStorage.setItem("idReg",_id);
  localStorage.setItem("idUsuario",_idReg);
  localStorage.setItem("idFnte",$("#Id_Fuente option:selected").val());
  localStorage.setItem("idFnteTit",$("#Id_Fuente option:selected").text());
  window.location.replace('links_act.html');
}


// Elimina un registro
function eliminar(_id, _table) {
  // alert('Eliminar '+_id);

  // Se abre el dialogo que pregunta ANTES de eliminar el registro
  swal({
    title: `Deseas eliminar el reg. Id(${_id})?`,
    text: `Esta acción no podra deshacerse!`,
    icon: 'warning',
    dangerMode: true,
    buttons: {
      cancel: 'Cancelar',
      delete: 'Si, Elimínalo!'
    }
  }).then(function (willDelete) {
    if (willDelete) {// Afirmativo se elimina el registro
      nauta.postData(
        'http://sau.test/api/usuarios/link/delLink',
        {
          "nick"  : dUser.nick,
          "token" : dUser.token,
          "id"    : _id.toString()
        }).then(function(data){

          let x = !!(data.status);
          if( x == true ){
            _table
              .row( '.selected' )
              .remove()
              .draw();
            swal("Listo! Ha sido eliminado!", {
              icon: "success",
            });
          }else{
            swal(`${data.msj}`, {
              title: 'Error en la acción!',
              icon: "error",
            });
          }

          
        });
    } else {
      swal("Se canceló la acción.", {
        title: '- Cancelado -',
        icon: "error",
      });
    }
  });


}


// Muestra un dialogo para cuando falta seleccionar un registro
function noRegSelec(){
  swal("Debes seleccionar un registro para realizar esta acción.", {
    title: 'Error en la acción!',
    icon: "error",
  });
}


// Se cancela la accion
function cancelar() {
  nauta.delId();
  localStorage.removeItem("idNick");
  window.location.replace('usuarios_lst.html');
}

