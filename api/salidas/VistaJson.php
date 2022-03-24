<?php
/**
 * Clase para imprimir en la salida respuestas con formato JSON
 */
class VistaJson
{

    // Codigo de error
    public $est;

    public function __construct($estado = 400)
    {
        $this->est = $estado;
    }

    /**
     * Imprime el cuerpo de la respuesta y setea el codigo de respuesta
     * @param mixed $cuerpo de la respuesta a enviar
     */
    public function imprimir($cuerpo)
    {
        if ($this->est) {
            http_response_code($this->est);
        }
        header('Access-Control-Allow-Origin: *');
        header("Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept");
		header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
        header('Content-Type: application/json; charset=utf8');
		
		header('P3P: CP="IDC DSP COR CURa ADMa OUR IND PHY ONL COM STA"');
        
		$json = json_encode($cuerpo, JSON_BIGINT_AS_STRING);
        
        //Se muestran los errores en la codificacion JSON
        switch(json_last_error()) {
            case JSON_ERROR_NONE:
                // $json .= ' - Sin errores';
                echo $json;
                break;
            case JSON_ERROR_DEPTH:
                // $json = ' - Excedido tamaño máximo de la pila';
                echo json_encode(JSON_ERR_DEPTH);
                break;
            case JSON_ERROR_STATE_MISMATCH:
                // $json = ' - Desbordamiento de buffer o los modos no coinciden';
                echo json_encode(JSON_ERR_STATE_MISMATCH);
                break;
            case JSON_ERROR_CTRL_CHAR:
                // $json = ' - Encontrado carácter de control no esperado';
                echo json_encode(JSON_ERR_CTRL_CHAR);
                break;
            case JSON_ERROR_SYNTAX:
                // $json = ' - Error de sintaxis, JSON mal formado';
                echo json_encode(JSON_ERR_SYNTAX);
                break;
            case JSON_ERROR_UTF8:
                // $json = ' - Caracteres UTF-8 malformados, posiblemente codificados de forma incorrecta';
                echo json_encode(JSON_ERR_UTF8);
                break;
            default:
                // $json = ' - Error desconocido';
                echo json_encode(JSON_ERR_DESCONOCIDO);
                break;
        }

        exit();
    }
}
?>