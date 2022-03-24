import * as nauta from "/web/vistas/js/nauta.js";
let dUser = nauta.getUser();
let tabla = null;

// ::::::::::::::: Se ejecuta al iniciar la carga de la pagina :::::::::::::::::::::
$(function () {
  // Se carga el menu lateral
  nauta.dMenu();

  // Cargar catalogos
  getCatNiveles();

  // Se carga el listado en la tabla
  lstUsuarios();

  //::::::::::::::::::: Barra de navegacion :::::::::::::::::::::
  nauta.dBarraNav();

  //:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


  // Cambiar Foto de perfil
  $("#btnFoto").click(function(){
    const _filaSelec = tabla.row('.selected').data();
    if (_filaSelec != null || _filaSelec != undefined) {
      nauta.setId(_filaSelec[0]);
      location.replace("usuario_foto.html");
    }else{
      noRegSelec();
    }
  });
  // Cambiar Password
  $("#btnPass").click(function(){
    const _filaSelec = tabla.row('.selected').data();
    if (_filaSelec != null || _filaSelec != undefined) {
      nauta.setId(_filaSelec[0][4]);
      location.replace("usuario_pass.html");
    }else{
      noRegSelec();
    }
  });
  // Cambiar Links
  $("#btnLinks").click(function(){
    const _filaSelec = tabla.row('.selected').data();
    if (_filaSelec != null || _filaSelec != undefined) {
      nauta.setId(_filaSelec[0][0]);
      localStorage.setItem("idNick", _filaSelec[0][4]);
      location.replace("links.html");
    }else{
      noRegSelec();
    }
  });

  
});
// :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::



/**
 * Obtiene el catalogo de niveles
 */
 function getCatNiveles(){
  nauta.postData(
    'http://sau.test/api/usuarios/nivel/lstNiveles',
    {
      "nick"   : dUser.nick,
      "token"  : dUser.token,
      "campos" : ["Id_UNivel"]
    }).then(function(resp){
      let x = nauta.cBooleano(resp.status);
      if( x == true ){
        let reg = resp.data;
        // console.log(reg);
        let opciones = "";
        if ( reg.length >= 1 ) {
          reg.forEach(valor => {
            opciones += `<option value="${valor.Id_UNivel}">${valor.Id_UNivel}</option>`
          });
          // Se almacena en localstorage
          localStorage.setItem('opcNiveles', opciones);
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
function lstUsuarios(){

  nauta.postData(
    'http://sau.test/api/usuarios/navegante/lstUsuarios',
    {
      "nick"  : dUser.nick,
      "token" : dUser.token,
      "campos": ["Id_Usuario", "Paterno", "Materno", "Nombre", "Nick", "Activo"]
    }).then(function(data){

      // Se inicializa el DataTables
      tabla = nauta.dibujarTabla("regs-tabla",data.data, ["Id", "Apellido Paterno", "Apellido Materno", "Nombre(s)", "Nombre de Usuario", "Activo"]);

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
          // let fila = tabla.row( $(this).parents("tr").eq(0));
          eliminar(id,tabla);
        } else {
          noRegSelec();
        }
      });
      // >>>>>>>>>>>>> FIN controladores para los botones de accion <<<<<<<<<<<<<<<<<
      
    }).catch(err => console.log(err));

}


// Abre la pagina para nuevo registro
function nuevo() {
  window.location.replace('usuario_nvo.html');
}


// Abre la pagina para actualizar registro
function actualizar(_id) {
  localStorage.setItem("idReg",_id);
  window.location.replace('usuario_act.html');
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
        'http://sau.test/api/usuarios/navegante/delUsuario',
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


// Muestra un dialogo para cuando falta seleccionar un registro
function noRegSelec(){
  swal("Debes seleccionar un registro para realizar esta acción.", {
    title: 'Error en la acción!',
    icon: "error",
  });
}

