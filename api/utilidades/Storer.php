<?php
error_reporting(E_ALL);
ini_set('display_errors', '1');

class Storer{
    public $stocker = array();
	public $stocker_error = array();
	public $cad = NULL;
    public $content = NULL;

    public function __construct($_list=NULL, $_getfiles=FALSE){
        $_content = $_SERVER['CONTENT_TYPE'];
        !empty( substr($_content,0,strpos($_content, ";")) )? $this->content=substr($_content,0,strpos($_content, ";")) : $this->content=$_content;
        if(!empty($_list)){
            if($_getfiles){
                $this->stocker = $this->getVars($_list, $_getfiles);
            }else{
                $this->stocker = $this->getVars($_list);
            }
        }
    }

    public function getVars(array $_list, $_getfiles=FALSE){
        $status = TRUE;
        $temp   = array();

        // Contenido JSON
        if($this->content == 'application/json'){
            // Se verifica si existen las variables en el cuerpo del archivo
            $temp = json_decode(file_get_contents('php://input'));
			$this->cad = $temp;
            if(!empty($temp)){
                foreach ($_list as $value) {
                    if(!property_exists($temp, $value)){
						$stocker_error[]= $value;
                        $status = FALSE;
                    }
                }
            }else{
                $status = FALSE;
            }
            
            return $this->stocker = $status?$temp:NULL;
            
        }elseif('multipart/form-data'){// Contenido de FILES
            $arr = array();
            //Se almacenan las variables recibidas via POST
            foreach ($_POST as $key => $value) {
                self::array_push_assoc( $arr, array($key => $value) );
            }
            if($_getfiles){// Si se solicito recuperar los archivos
                foreach($_FILES as $key => $value){
                    // Se almacenan los archivos recibidos tanto 'stocker'
                    // como en 'filesrack'
                    self::array_push_assoc( $arr, array($key => $value) );
                    
                }
            }
            // Se verifica si existen las variables en el cuerpo del archivo
            $temp = (object) $arr;
            foreach ($_list as $value) {
                if(!property_exists($temp, $value)){
                    $status = FALSE;
                }
            }
            return $this->stocker = $status?$temp:NULL;

        }else{
            return $this->stoker = NULL;
        }
    }

    /***********************************
     *	Combinar arreglos asociativos  *
    ***********************************/
    //Funcion para insertar valores en arreglos asociativos
    public static function array_push_assoc(array &$arrayDatos, array $values) {
        $arrayDatos = array_merge($arrayDatos, $values);
    }
}
?>