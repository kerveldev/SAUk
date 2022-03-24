import * as nauta from "/web/vistas/js/nauta.js";
let dUser = nauta.getUser();
let tabla = null;

// ::::::::::::::: Se ejecuta al iniciar la carga de la pagina :::::::::::::::::::::
$(function () {

  // Se carga el menu lateral
  nauta.dMenu();

  // Se carga el listado en la tabla
  lstRegistros();

 //::::::::::::::::::: Barra de navegacion :::::::::::::::::::::
 nauta.dBarraNav();

 //:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  
});
// :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


/**
 * Carga el listado en la tabla indicada
 */
function lstRegistros(){

  nauta.postData(
    'http://sau.test/api/usuarios/fuentes/lstFuentes',
    {
      "nick"  : dUser.nick,
      "token" : dUser.token,
      "campos": ["Id_Fuente", "Fuente"]
    }).then(function(data){

      // Se inicializa el DataTables
      tabla = nauta.dibujarTabla("regs-tabla",data.data, ["Id", "Fuente"]);

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
          swal("Debes seleccionar un registro para realizar esta acción.", {
            title: 'Error en la acción!',
            icon: "error",
          });
        }
      });

      // Eliminar
      $(".btn-warning-cancel").click( function(f){
        let r = tabla.row( '.selected' ).data();
        if (r!=undefined || r!=null) {
          let id = tabla.row('.selected').data()[0];
          // let fila = tabla.row( $(this).parents("tr").eq(0));
          eliminar(id,tabla);
        } else {
          swal("Debes seleccionar un registro para realizar esta acción.", {
            title: 'Error en la acción!',
            icon: "error",
          });
        }
      });
      // >>>>>>>>>>>>> FIN controladores para los botones de accion <<<<<<<<<<<<<<<<<
      
    }).catch(err => console.log(err));

}

// Abre la pagina para nuevo registro
function nuevo() {
  window.location.replace('fuentes_nvo.html');
}

// Abre la pagina para actualizar registro
function actualizar(_id) {
  localStorage.setItem("idReg",_id);
  window.location.replace('fuentes_act.html');
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
        'http://sau.test/api/usuarios/fuentes/delFuente',
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

            // NOTA: Si la carpeta del usuario no existe,
            // se manda un FALSE, pero en realidad si se 
            // elimino el usuario, solo que no existía la
            // carpeta del mismo.

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

