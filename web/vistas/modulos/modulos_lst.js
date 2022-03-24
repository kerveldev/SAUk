import * as nauta from "/web/vistas/js/nauta.js";
let dUser = nauta.getUser();
let tabla = null;

// ::::::::::::::: Se ejecuta al iniciar la carga de la pagina :::::::::::::::::::::
$(function () {

  // Se carga el menu lateral
  nauta.dMenu();

  // Cargar catalogos
  getCatGrupos();

  // Se carga el listado en la tabla
  lstRegistros();

  //::::::::::::::::::: Barra de navegacion :::::::::::::::::::::
  nauta.dBarraNav();

  //:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  
});
// :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


/**
 * Obtiene el catalogo de grupos
 */
function getCatGrupos(){
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
          // Se almacena en localstorage
          localStorage.setItem('opcGrupos', opciones);
        }

      }else{
        console.log("No se pudo cargar el listado de tipos.");
      }
    }).catch(function(err){
      console.log(`Error en petición: ${err}`);
    });
}

/**
 * Carga el listado en la tabla indicada
 */
function lstRegistros(){

  nauta.postData(
    'http://sau.test/api/usuarios/modulo/lstModulos',
    {
      "nick"  : dUser.nick,
      "token" : dUser.token,
      "campos": ["Id_Modulo","Modulo","Ruta", "Grupo"],
      "anexar" :[ 
          {
              "tabla" : "modulos_grupo",
                 "id" : "Id_Grupo",
            "id_join" : "Grupo",
             "campos" : [ "Grupo" ]
          }
      ]
    }).then(function(data){

      // Se inicializa el DataTables
      tabla = nauta.dibujarTabla("regs-tabla",data.data, ["Id","Modulo","Ruta", "Grupo"]);

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
  window.location.replace('modulos_nvo.html');
}

// Abre la pagina para actualizar registro
function actualizar(_id) {
  localStorage.setItem("idReg",_id);
  window.location.replace('modulos_act.html');
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
        'http://sau.test/api/usuarios/modulo/delModulo',
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

