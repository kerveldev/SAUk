<?php
switch($recurso){

    case 'test':
        $v= require_once(TEST['test']);
        if($v==TRUE){
            $l = peticion($peticion);
            $l['status']?$vista->est=200:$vista->est=400;
            $vista->imprimir($l);
        }else{
            $vista->est = 400;
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