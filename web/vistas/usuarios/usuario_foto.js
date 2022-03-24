import * as nauta from "/web/vistas/js/nauta.js";
let dUser  = nauta.getUser();
let _idReg = nauta.getId("idReg");
let vCampo = null;

// ::::::::::::::: Se ejecuta al iniciar la carga de la pagina :::::::::::::::::::::
$(function () {
  // Se carga el menu lateral
  nauta.dMenu();

  //::::::::::::::::::: Barra de navegacion :::::::::::::::::::::
  nauta.dBarraNav();

  //:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

  $("#imgFotoPerfil").prop("src",`../../app-assets/images/sinFotoPerfil.png`);
  
  // Se verifica el idReg y se cargan los datos
  if (_idReg != null && _idReg != undefined) {
    cargarRegistro(_idReg);
  } else {
    swal("No se encontro el Id del Registro.", {
      title : 'Error!',
      icon  : "error",
    });
  }


  // Inicializacion de Dropify
  // Used events
  var drEvent = $('.dropify-event').dropify();

  drEvent.on('dropify.beforeClear', function(event, element){
      return confirm("Do you really want to delete \"" + element.filename + "\" ?");
  });

  drEvent.on('dropify.afterClear', function(event, element){
      alert('File deleted');
  });


  // Cancelar
  $("#btnCancelar").click(function(){
    cancelar();
  });

  // Guardar btnGuardar
  $("#btnGuardar").click(function(){
    subirArchivo();
  });

});
// :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


/**
 * Carga los datos del registro por el idReg
 */
function cargarRegistro(_id){
  nauta.postData(
    'http://sau.test/api/usuarios/navegante/fotoPerfilVer',
    {
      "nick"   : dUser.nick,
      "token"  : dUser.token,
      "id"     : _id
    }).then(function(resp){
      let x = nauta.cBooleano(resp.status);
      if( x == true ){

        if(resp.data != null || resp.data != undefined){
          const reg = resp.data[0];
          $("#imgFotoPerfil").prop("src",`http://${reg.Vista_previa}`);
        }else{
          $("#imgFotoPerfil").prop("src",`../../app-assets/images/sinFotoPerfil.png`);
        }

        // console.log(reg);

        // Se cargan los datos

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
  const tipos = ["image/png","image/jpeg","image/jpg"]; // 8000000
  const _files = $("#nvaFotoPerfil").prop('files');

  // Validaciones
  console.log(_files);

  // No hay archivos
  if ( _files.length < 1) {
    vCampo = "No hay archivos seleccionados!";
    return false;
  }

  // Tipo
  if (!tipos.includes(_files[0].type) ) {
    vCampo = "Tipo de archivo no valido!";
    return false;
  }

  // Tamaño
  if (!_files.size > 8388608 ) {
    vCampo = "El tamaño del archivo excede los 8 megas!";
    return false;
  }


  return true;
}


/**
 * Guarda el nuevo registro
 */
function subirArchivo(){
  let valido = preparaCampos();

  if (valido == true) {
    let fData = new FormData();
    let fField = document.querySelector("input[type='file']");

    fData.append('nick', dUser.nick);
    fData.append('token', dUser.token);
    fData.append('id', _idReg);
    fData.append('perfil', fField.files[0]);
    
    nauta.postForm(
      'http://sau.test/api/usuarios/navegante/fotoPerfilCargar', fData)
      .then(function(data){
        let x = !!(data.status);
        if( x == true ){
          swal("Listo! Registro creado con éxito!", {
            icon: "success",
          });
          cargarRegistro(_idReg);
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
    swal(`Error: ${vCampo}.`, {
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

