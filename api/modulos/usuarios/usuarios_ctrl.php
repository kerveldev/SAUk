<?php
switch($recurso){

    case 'logger':
        $v= require_once(USUARIOS['logger']);
        if($v==TRUE){
            $l = peticion($peticion);
            !empty($l)?$vista->est=200:$vista->est=400;
            $vista->imprimir($l);
        }else{
            $vista->estado = 400;
            $vista->imprimir(RECURSO_NO_IMPLEMENTADO);
        }
        
        break;

    case 'navegante':
        $v= require_once(USUARIOS['navegante']);
        if($v==TRUE){
            $l = peticion($peticion);
            !empty($l)?$vista->est=200:$vista->est=400;
            $vista->imprimir($l);
        }else{
            $vista->estado = 400;
            $vista->imprimir(RECURSO_NO_IMPLEMENTADO);
        }
        
        break;
        
    case 'modulo':
        $v= require_once(USUARIOS['modulo']);
        if($v==TRUE){
            $l = peticion($peticion);
            !empty($l)?$vista->est=200:$vista->est=400;
            $vista->imprimir($l);
        }else{
            $vista->estado = 400;
            $vista->imprimir(RECURSO_NO_IMPLEMENTADO);
        }
        
        break;
        
    case 'grupo':
        $v= require_once(USUARIOS['grupo']);
        if($v==TRUE){
            $l = peticion($peticion);
            !empty($l)?$vista->est=200:$vista->est=400;
            $vista->imprimir($l);
        }else{
            $vista->estado = 400;
            $vista->imprimir(RECURSO_NO_IMPLEMENTADO);
        }
        
        break;
        
    case 'nivel':
        $v= require_once(USUARIOS['nivel']);
        if($v==TRUE){
            $l = peticion($peticion);
            !empty($l)?$vista->est=200:$vista->est=400;
            $vista->imprimir($l);
        }else{
            $vista->estado = 400;
            $vista->imprimir(RECURSO_NO_IMPLEMENTADO);
        }
        
        break;
        
    case 'link':
        $v= require_once(USUARIOS['link']);
        if($v==TRUE){
            $l = peticion($peticion);
            !empty($l)?$vista->est=200:$vista->est=400;
            $vista->imprimir($l);
        }else{
            $vista->estado = 400;
            $vista->imprimir(RECURSO_NO_IMPLEMENTADO);
        }
        
        break;

    case 'fuentes':
        $v= require_once(USUARIOS['fuentes']);
        if($v==TRUE){
            $l = peticion($peticion);
            !empty($l)?$vista->est=200:$vista->est=400;
            $vista->imprimir($l);
        }else{
            $vista->estado = 400;
            $vista->imprimir(RECURSO_NO_IMPLEMENTADO);
        }
        
        break;
    
    // ******* Recursos no existente para 'test' *******
    default:
        $vista->est = 400;
        $vista->imprimir(RECURSO_NO_EXISTE);
        break;

}// Fin switch
?>