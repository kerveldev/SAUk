const opcs = 
{
    "principal":{
        "link"       : "/web/vistas/saudashb/sau_board.html",
        "logo"       : "/web/app-assets/images/logo/materialize-logo.png",
        "logo_color" : "/web/app-assets/images/logo/materialize-logo-color.png",
        "ico"        : "home",
        "title"      : "SAU"
    },
    "opciones":[
        {
            "link"  : "/web/vistas/usuarios/usuarios_lst.html",
            "ico"   : "contacts",
            "title" : "Usuarios"
        },
        {
            "link"  : "/web/vistas/modulos/modulos_lst.html",
            "ico"   : "developer_board",
            "title" : "Modulos"
        },
        {
            "link"  : "/web/vistas/modulos_grupo/modulos_grupo_lst.html",
            "ico"   : "style",
            "title" : "Grupos"
        },
        {
            "link"  : "/web/vistas/niveles/niveles_lst.html",
            "ico"   : "clear_all",
            "title" : "Niveles"
        },
        {
            "link"  : "/web/vistas/fuentes/fuentes_lst.html",
            "ico"   : "queue_play_next",
            "title" : "Fuentes"
        }
    ]
};


/**
 * Peticion general POST, solo funciona para JSON.
 * @param {*} url Direccion url de la peticion.
 * @param {*} data Cuerpo de la peticion, debe estar en formato JSON.
 * @returns Retorna el objeto JSON parseado.
 * 
 * MDN Web Docs community
 */
function postData(url, data) {
    const r =  new Promise( (resolve) => {

        fetch(url, 
            {
                method         : 'POST', 
                mode           : 'cors', 
                cache          : 'no-cache', 
                credentials    : 'same-origin', 
                headers : 
                {
                  'Content-Type': 'application/json'
                },
                redirect       : 'follow', 
                referrerPolicy : 'no-referrer', 
                body           : JSON.stringify(data) 
        })
        .then(response => response.json())
        .then(datos => resolve(datos) )
        .catch((err)=>err);

    })

    return r;
}


/**
 * Peticion general POST, solo funciona para JSON.
 * @param {*} url Direccion url de la peticion.
 * @param {*} fData Formulari a enviar.
 * @returns Retorna el objeto JSON parseado.
 * 
 * MDN Web Docs community
 */
 function postForm(url, fData) {
    const r =  new Promise( (resolve) => {

        fetch(url, 
            {
                method : 'POST',
                body   : fData 
        })
        .then(response => response.json())
        .then(datos => resolve(datos) )
        .catch((err)=>err);

    })

    return r;
}


/**
 * Dibuja una tabla en formato html en el contenedor indicado.
 * El primer elmento del parametro 'datos' debe ser el Id del registro.
 * 
 * @param {*} idTabla (String) Id del elemento HTML de la tabla a inicializar.
 * @param {*} datos   (opcional) Arreglo con los registros de la tabla.
 * @param {*} titulos (opcional) Titulos personalizados para la tabla, estos deben de corresponder con 'Datos'.
 * 
 */
 function dibujarTabla(idTabla, datos=null, titulos=null){
    let   cadena      = "";
    let   _titulos    = null;

    // Si no existen los datos para crear la tabla solo se aplica el PlugIn
    if( datos != null ){
        // Si existen datos
        if (datos.length>0) {
            // Seccion de los titulos de la tabla :::::::::::::::::::::::::::::
            if( titulos != null && Array.isArray(titulos)){
                if (titulos.length>0) {
                    cadena += `<thead><tr>`;
                    titulos.forEach(titulo => cadena += `<th>${titulo}</th>`);
                    cadena += `</thead>`;// Se agrega la columna acciones
                }
            }else{
            // NO hay titulos se colocan los nombres de clave del objeto
                _titulos = Object.keys(datos[0]);
                cadena += `<thead><tr>`;
                _titulos.forEach(titulo => cadena += `<th>${titulo}</th>`);
                cadena += `</thead>`;// Se agrega la columna acciones
            }
            // FIN Seccion de los titulos de la tabla :::::::::::::::::::::::::::::
            
            // Seccion de los registros de la tabla :::::::::::::::::::::::::::::
            cadena += "<tbody>";
            datos.forEach(function(reg) {
                for (const valor in reg) cadena+=`<td>${(reg[valor]==null)||(reg[valor]=="")?"":reg[valor]}</td>`;
                cadena += "</tr>";
            });
            // Seccion de los registros de la tabla :::::::::::::::::::::::::::::
            
            // console.log(cadena);
            $(`#${idTabla}`).html(cadena);
        }
    }else{
        cadena += "<thead><tr><th>Datos</th></tr></thead><tbody><tr><td>Sin Datos</td></tr></tbody>";
        // console.log(cadena);
        $(`#${idTabla}`).html(cadena);
    }

    // Se carga el plugIn DataTables
    return cargarDT(idTabla);

}



/**
 * Dibuja una tabla en formato html en el contenedor indicado.
 * El primer elmento del parametro 'datos' debe ser el Id del registro.
 * 
 * @param {*} idTabla (String) Id del elemento HTML de la tabla a inicializar.
 * @param {*} datos   (opcional) Arreglo con los registros de la tabla.
 * @param {*} titulos (opcional) Titulos personalizados para la tabla, estos deben de corresponder con 'Datos'.
 * 
 */
 function dibujarTablaSinDT(idTabla, datos=null, titulos=null){
    let   cadena      = "";
    let   _titulos    = null;

    // Si no existen los datos para crear la tabla solo se aplica el PlugIn
    if( datos != null ){
        // Si existen datos
        if (datos.length>0) {
            // Seccion de los titulos de la tabla :::::::::::::::::::::::::::::
            if( titulos != null && Array.isArray(titulos)){
                if (titulos.length>0) {
                    cadena += `<thead><tr>`;
                    titulos.forEach(titulo => cadena += `<th>${titulo}</th>`);
                    cadena += `</thead>`;// Se agrega la columna acciones
                }
            }else{
            // NO hay titulos se colocan los nombres de clave del objeto
                _titulos = Object.keys(datos[0]);
                cadena += `<thead><tr>`;
                _titulos.forEach(titulo => cadena += `<th>${titulo}</th>`);
                cadena += `</thead>`;// Se agrega la columna acciones
            }
            // FIN Seccion de los titulos de la tabla :::::::::::::::::::::::::::::
            
            // Seccion de los registros de la tabla :::::::::::::::::::::::::::::
            cadena += "<tbody>";
            datos.forEach(function(reg) {
                for (const valor in reg) cadena+=`<td>${(reg[valor]==null)||(reg[valor]=="")?"":reg[valor]}</td>`;
                cadena += "</tr>";
            });
            // Seccion de los registros de la tabla :::::::::::::::::::::::::::::
            
            // console.log(cadena);
            $(`#${idTabla}`).html(cadena);
        }
    }else{
        cadena += "<thead><tr><th>Datos</th></tr></thead><tbody><tr><td>Sin Datos</td></tr></tbody>";
        // console.log(cadena);
        $(`#${idTabla}`).html(cadena);
    }


}


/**
 * Inicializa una tabla con el plugin Datatables, colocando una configuración básica.
 * 
 * @param {*} idTabla (String) Id del elemento HTML de la tabla a inicializar.
 * @param {*} _select (opcional) Indica si se pueden seleccionar las filas.
 * @returns Retorna el objeto Datatables.
 */
 function cargarDT(idTabla){
     //'  '<i class="material-icons">edit</i>'
    // Se aplica el plugin DataTables a la tabla 
    let tabla = $(`#${idTabla}`).DataTable({
        responsive  : true,
        destroy     : true,
        bProcessing : true,
        processing  : true,
        searching   : true,
        select      : true,
        dom         : 
            `
            <'row'<'col-sm-12 col-md-4 col-xl-5' i ><'col-sm-12 col-md-2 col-xl-2'><'col-sm-12 col-md-6 col-xl-5' f >>
            <'row'<'col-sm-16' tr >>
            <'row'<'col-sm-12 col-md-3 col-xl-3' l ><'col-sm-12 col-md-3 col-xl-2'><'col-sm-12 col-md-6 col-xl-7' p >>
            <'row'<'col-sm-16' B >>
            `,
        buttons: 
        [
            {
                text          : '<a class="btnElim btn-warning-cancel btn-floating mb-1 waves-effect waves-light green" ><i class="material-icons">add</i></a>',
                titleAttr     : 'Nuevo',
                className     : 'btnNvoDT'
            },
            {
                text          : '<a class="btnAct btn-floating mb-1 waves-effect waves-light blue darken-3" ><i class="material-icons">edit</i></a>',
                titleAttr     : 'Actualizar',
                className     : 'btnActDT'
            },
            {
                text          : '<a class="btnElim btn-warning-cancel btn-floating mb-1 waves-effect waves-light red" ><i class="material-icons">delete_forever</i></a>',
                titleAttr     : 'Eliminar',
                className     : 'btnElimDT'
            },
            {
                extend : 'spacer',
                style  : 'bar'
            },
            {
                extend        : 'excel',
                text          : 'Excel',
                titleAttr     : 'Descargar archivo de Excel',
            },
            
        ],
        scrollY        : '110vh',
        scrollCollapse : true,
        // Lenguaje en español
        language : {
            decimal        : ".",
            thousands      : ",",
            info           : "Mostrando registros del _START_ al _END_ de un total de _TOTAL_ registros",
            infoEmpty      : "Mostrando registros del 0 al 0 de un total de 0 registros",
            infoPostFix    : "",
            infoFiltered   : "(filtrado de un total de _MAX_ registros)",
            loadingRecords : "Cargando...",
            lengthMenu     : "Mostrar _MENU_ registros",
            paginate : 
            {
                first    : "Primero",
                last     : "Último",
                next     : "Siguiente",
                previous : "Anterior"
            },
            processing     : "Procesando...",
            search         : "Buscar:",
            searchPlaceholder : "Término de búsqueda",
            zeroRecords    : "No se encontraron resultados",
            emptyTable     : "Ningún dato disponible en esta tabla",
            aria : 
            {
                sortAscending  :  ": Activar para ordenar la columna de manera ascendente",
                sortDescending : ": Activar para ordenar la columna de manera descendente"
            },
            buttons : //only works for built-in buttons, not for custom buttons
            {
                create  : "Nuevo",
                edit    : "Cambiar",
                remove  : "Borrar",
                copy    : "Copiar",
                csv     : "fichero CSV",
                excel   : "tabla Excel",
                pdf     : "documento PDF",
                print   : "Imprimir",
                colvis  : "Visibilidad columnas",
                collection : "Colección",
                upload  : "Seleccione fichero...."
            },
            select : 
            {
                rows : 
                {
                    _: '%d filas seleccionadas',
                    0: 'clic fila para seleccionar',
                    1: 'una fila seleccionada'
                }
            }
        }
    });

    return tabla;

}


/**
 * Solicita el acceso a la plataforma.
 * @param {*} nick Nombre de usuario.
 * @param {*} pass Constraseña.
 * @param {*} fnte (opcional) Fuente desde la que solicita el acceso.
 * @param {*} lat  (opcional) Latitud.
 * @param {*} long (opcional) Longitud.
 * 
 * @returns Retorna el objeto del usuario JSON parseado.
 * 
 */
async function login(nick, pass, fnte='WEB', lat=0.0, lng=0.0 ) {

    const data = {
        "nick"   : nick,
        "pass"   : pass,
        "fuente" : fnte,
        "lat"    : lat.toString(),
        "lng"    : lng.toString()
    }

    const response = await fetch("http://sau.test/api/usuarios/logger/login", 
        {
            method         : 'POST',
            mode           : 'cors',
            cache          : 'no-cache',
            credentials    : 'same-origin',
            headers : 
            {
              'Content-Type': 'application/json'
            },
            redirect       : 'follow',
            referrerPolicy : 'no-referrer',
            body           : JSON.stringify(data)
    });
    return response.json(); 
}


/**
 * Cierra la sesion en la plataforma.
 * @param {*} nick Nombre de usuario.
 * @param {*} fnte (opcional) Fuente desde la que solicita el cierre.
 * @param {*} lat  (opcional) Latitud.
 * @param {*} long (opcional) Longitud.
 * @returns Retorna el objeto del usuario JSON parseado.
 * 
 */
async function logout(nick, fnte='WEB', lat=0.0, lng=0.0 ) {

    const data = {
        "nick"   : nick,
        "fuente" : fnte,
        "lat"    : lat.toString(),
        "lng"    : lat.toString()
    }

    const response = await fetch("http://sau.test/api/usuarios/logger/logout", 
        {
            method         : 'POST',
            mode           : 'cors',
            cache          : 'no-cache',
            credentials    : 'same-origin',
            headers : 
            {
              'Content-Type': 'application/json'
            },
            redirect       : 'follow',
            referrerPolicy : 'no-referrer',
            body           : JSON.stringify(data)
    });
    return response.json(); 
}



/**
 * Obtiene los datos del usuario almacenados en localstorage.
 * @returns Retorna un objeto con los datos del usuario.
 * 
 */
function getUser() {
    let uTemp = localStorage.getItem("us");
    if( uTemp != null ){
        return JSON.parse( atob(uTemp) );
    }else{
        return false;
    }
}



/**
 * Guarda el Id del registro almacenado en localstorage.
 * @returns Retorna un Id para trabajar con el registro.
 * 
 */
function setId(_id) {
    localStorage.setItem("idReg", _id);
}


/**
 * Obtiene el Id del registro almacenado en localstorage.
 * @returns Retorna un Id para trabajar con el registro.
 * 
 */
function getId() {
    let uTemp = localStorage.getItem("idReg");
    if( uTemp != null ){
        return uTemp;
    }else{
        return null;
    }
}


/**
 * Elimina el Id del registro almacenado en localstorage.
 * @returns Retorna un Id para trabajar con el registro.
 * 
 */
 function delId() {
    let uTemp = localStorage.getItem("idReg");
    if( uTemp != null ){
        return localStorage.removeItem("idReg");;
    }else{
        return null;
    }
}


/**
 * Limpia todo el localstorage a excepcion de los datos del usuario.
 * @returns Retorna un Id para trabajar con el registro.
 * 
 */
 function limpiarCache() {
    const _us = localStorage.getItem("us");
    localStorage.clear();
    localStorage.setItem("us",_us);
}



/**
 * Convierte una cadena en boolean.
 * @returns Retorna true/false.
 * 
 */
function cBooleano(_v) {
    if      (_v == null) return false;
    else if (_v == undefined) return false;
    else if (typeof _v == 'boolean') return _v;
    else if (typeof _v == 'string') {
        switch(_v.toLowerCase().trim()){
            case "yes": case "on" : case "ok" : case "true" : return true;
            case "no" : case "off": case "not": case "false": return false;
            default: 
                let numero = parseInt(_v);
                if ( numero != NaN && numero >= 1 ){return true;}else{return false;};
        }
    } else if (typeof _v == 'number'){
        if ( _v >= 1 ){return true;}else{return false;}
    }else return false;
}



/**
 * Dibuja el menu con el formato de esta plantilla. Se basa en el json recibido
 * @returns Retorna true/false.
 * 
 */
function dMenu() {
    const hMenu = document.getElementById('hMenu');
    const oMenu = document.getElementById('oMenu');
    let strHead     = "";
    let strOpciones = "";


    strHead = 
    `<h1 class="logo-wrapper">
        <a class="brand-logo darken-1" href="${opcs.principal.link}">
            <img class="hide-on-med-and-down" src="${opcs.principal.logo}" alt="SAU logo" />
            <img class="show-on-medium-and-down hide-on-med-and-up" src="${opcs.principal.logo_color}" alt="SAU logo" />
            <span class="logo-text hide-on-med-and-down">${opcs.principal.title}</span>
        </a>
        <a class="navbar-toggler" href="#"><i class="material-icons">radio_button_checked</i></a>
    </h1>`;

    opcs.opciones.forEach((o)=>{
        strOpciones += 
        `<li class="active bold"><a class="waves-effect waves-cyan " href="${o.link}"><i class="material-icons">${o.ico}</i><span class="menu-title" data-i18n="Users">${o.title}</span></a></li>`
    });
    
    hMenu.innerHTML = strHead;
    oMenu.innerHTML = strOpciones;
}

/**
 * Dibuja el menu con el formato de esta plantilla. Se basa en el json recibido
 * @returns Retorna true/false.
 * 
 */
function dBarraNav() {
    const _dUser = getUser();

    // Se verifica el idReg y se cargan los datos
    if (_dUser != null && _dUser != undefined) {
        // Avatar
        if (_dUser.VistaPrevia != null || _dUser.VistaPrevia != undefined) {
            $("#avatar").prop("src","http://"+_dUser.VistaPrevia);
        } else {
            $("#avatar").prop("src",`../../app-assets/images/sinFotoPerfil.png`);
        }

        // Nombre de usuario
        $("#uNick").text(_dUser.nick);

        // Logout
        $("#salir").click(
            ()=>nauta.logout(_dUser.nick)
            .then(data => {
            // console.log(data);
            if (data.status == 'TRUE') {
                window.location.replace("http://sau.test");
            }else{
                alert(data.msj);
            }
            }).catch(err => console.log(err))
        );
    } else {
        swal("No se encontro información de sesion de usuario. Tendrá que reingresar a la plataforma.", {
        title : 'Error!',
        icon  : "error",
        });
        window.location.replace("http://sau.test");
    }
}


// Se exportan las funciones
export { postData, postForm, dibujarTabla, dibujarTablaSinDT, cargarDT, login, logout, getUser, setId, getId, delId, limpiarCache, cBooleano, dMenu, dBarraNav };