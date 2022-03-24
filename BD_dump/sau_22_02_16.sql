-- phpMyAdmin SQL Dump
-- version 5.1.1
-- https://www.phpmyadmin.net/
--
-- Servidor: localhost:3306
-- Tiempo de generación: 16-02-2022 a las 20:49:32
-- Versión del servidor: 5.7.33
-- Versión de PHP: 7.4.19

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `sau`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `checkuser` (IN `_nick` VARCHAR(50), IN `_token` VARCHAR(40))  NO SQL
BEGIN
SET @cant = 0;
SET @id = null;
SET @last_login = null;
SET @cant_us = 0;

#Se verifica que exista el nick
SELECT COUNT(ng.Id_Usuario) INTO @cant_us 
FROM navegantes ng WHERE ng.Nick LIKE _nick;

# Si existe el nick
IF NOT _nick IS NULL AND @cant_us > 0 THEN

	#Se valida el usuario buscando el nick y el token
	SELECT COUNT(n.Id_Usuario) INTO @cant 
    FROM navegantes n WHERE n.Nick LIKE _nick AND n.Token LIKE _token;
        
	# Si es un usuario valido
	IF NOT _token IS NULL AND @cant > 0 THEN
    	
        #Primero: Se obtiene el id
    	SELECT nv.Id_Usuario INTO @id 
        FROM navegantes nv 
        WHERE nv.Nick LIKE _nick AND nv.Token LIKE _token;
        
        #Segundo: Se obtiene la hora fecha del ultimo registro en accesos
        SELECT ac.Id_Acceso INTO @last_login 
        FROM accesos ac
        WHERE ac.Id_Usuario = @id
        ORDER BY ac.Id_Acceso DESC LIMIT 1;
            
        #Tercero: Se muestra la informacion
        SELECT 
            (True) AS status,
            ('Usuario valido') AS msj,
            @id AS Id_Usuario,
            (@last_login) AS last_login,
            a.Tipo_Acceso,
            a.Fecha,
            f.Fuente,
            a.Latitud,
            a.Longitud
        FROM accesos a
        LEFT JOIN fuentes f ON(a.Id_Fuente = f.Id_Fuente)
        WHERE a.Id_Acceso = @last_login;
        
    ELSE
    	SELECT 
        (False) AS status,
        ('Token invalido')AS msj;
    END IF;
    
ELSE
   SELECT 
    (False) AS status,
    ('Usuario incorrecto')AS msj;
END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `inserta_usuario` (IN `_pat` VARCHAR(50), IN `_mat` VARCHAR(50), IN `_nom` VARCHAR(50), IN `_nick` VARCHAR(50), IN `_pass` VARCHAR(50))  NO SQL
BEGIN

SET @id = NULL;

INSERT INTO navegantes
 (Paterno, Materno, Nombre, Nick)
VALUES 
 (_pat, _mat, _nom, _nick);

SELECT last_insert_id() INTO @id;

#Usamos AES en 'aes-256-ecb';
SET @@session.block_encryption_mode = 'aes-256-ecb';

#Encriptamos la contraseña junto con el nick
UPDATE navegantes n
 SET n.Pass = AES_ENCRYPT(_pass,@id)
WHERE n.Id_Usuario = @id;
 
IF @id IS NULL THEN
	SELECT FALSE AS Status, 
           "Error al crear el usuario" AS Msj;
ELSE
	SELECT TRUE AS Status,
    	   @id AS Id,
           CONCAT(@id," Usuario creado") AS Msj;
END IF;
 
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `login` (IN `_nick` VARCHAR(50), IN `_pass` VARCHAR(50), IN `_disp` VARCHAR(50), IN `_lat` VARCHAR(50), IN `_lng` VARCHAR(50))  BEGIN
SET @id   = NULL;
SET @acc  = 0;
SET @disp = NULL;
SET @cdis = 0;
SET @lat  = NULL;
SET @lng  = NULL;
SET @@session.block_encryption_mode = 'aes-256-ecb';

#Se comprueban los valores de disp
IF LENGTH(_disp)>0 OR NOT _disp IS NULL THEN
	#Se busca el disp en la tabla fuentes
    SELECT COUNT(f.Id_Fuente) INTO @cdis 
    FROM fuentes f WHERE f.Fuente LIKE _disp;
END IF;

#Se comprueban los valores de lat
IF LENGTH(_lat)>0 OR NOT _lat IS NULL THEN
	SET @lat = _lat;
END IF;

#Se comprueban los valores de lng
IF LENGTH(_lng)>0 OR NOT _lng IS NULL THEN
	SET @lng = _lng;
END IF;

SELECT n.Id_Usuario INTO @id FROM navegantes AS n WHERE n.Nick LIKE _nick;

SELECT COUNT(g.Id_Usuario) INTO @acc 
FROM navegantes as g 
WHERE g.Pass = AES_ENCRYPT(_pass,@id);

# Si existe el disp en la tabla fuentes 
IF @cdis > 0 THEN

#se obtiene el Id_Dispositivo
SELECT f.Id_Fuente INTO @disp
    FROM fuentes f WHERE f.Fuente LIKE _disp;

# SI existe el nick
IF NOT @id IS NULL THEN

 IF @acc > 0 THEN          
   #Primero: se genera el token
   SET @tok = SHA1(CONCAT(SYSDATE(6),@id));
        
   #Segundo: se guarda en el navegante correspondiente
   UPDATE navegantes na SET 
   	na.Token   = @tok,
    na.EnLinea = 1
   WHERE na.Id_Usuario = @id;
   
   INSERT INTO accesos (
    Id_Usuario, 
   	Tipo_Acceso,
   	Id_Fuente,
   	Latitud,
    Longitud)
   VALUES (
       @id,
       "LOGIN",
       @disp,
       @lat,
       @lng
   );
        
   #Tercero: se retorna el token
   SELECT
    (TRUE) AS status,
    ('Acceso autorizado')AS msj,
    nv.Nick,
    nv.Token,
    nv.Paterno,
    nv.Materno,
    nv.Nombre,
    nv.Nivel,
    nv.Activo,
    nv.EnLinea,
    m.Vista_previa
   FROM navegantes nv
   LEFT JOIN multimedia m ON(
       m.Tabla LIKE 'navegantes'
       AND m.Tabla_Id LIKE @id
       AND m.Tipo_archivo LIKE 'PERFIL'
   	)
   WHERE nv.Id_Usuario = @id;
 ELSE
   #Contraseña incorrecta
   SELECT 
    	(FALSE) AS status,
    	('Contraseña incorrecta') AS msj;
 END IF;
ELSE
   SELECT 
    (FALSE) AS status,
    ('Nombre de usuario inexistente') AS msj;
END IF;

ELSE
SELECT 
    (FALSE) AS status,
    ('Fuente no autorizada') AS msj;
END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `logout` (IN `_nick` VARCHAR(50), IN `_disp` VARCHAR(30), IN `_lat` VARCHAR(50), IN `_lng` VARCHAR(50))  BEGIN
SET @id = NULL;
SET @acc = 0;
SET @disp = NULL;
SET @cdis = 0;
SET @lat  = NULL;
SET @lng  = NULL;

#Se comprueban los valores de disp
IF LENGTH(_disp)>0 OR NOT _disp IS NULL THEN
	#Se busca el disp en la tabla fuentes
    SELECT COUNT(f.Id_Fuente) INTO @cdis 
    FROM fuentes f WHERE f.Fuente LIKE _disp;
END IF;

#Se comprueban los valores de lat
IF LENGTH(_lat)>0 OR NOT _lat IS NULL THEN
	SET @lat = _lat;
END IF;

#Se comprueban los valores de lng
IF LENGTH(_lng)>0 OR NOT _lng IS NULL THEN
	SET @lng = _lng;
END IF;

# Si existe el disp en la tabla fuentes 
IF @cdis > 0 THEN

#se obtiene el Id_Dispositivo
SELECT f.Id_Fuente INTO @disp
    FROM fuentes f WHERE f.Fuente LIKE _disp;
    

SELECT n.Id_Usuario INTO @id 
FROM navegantes AS n 
WHERE n.Nick LIKE _nick;

#Existe el nick?
IF NOT @id IS NULL THEN
	
  #Primero: se borra el token del registro del usuario
  UPDATE navegantes na SET 
  	na.Token   = NULL,
    na.EnLinea = -1
  WHERE na.Id_Usuario = @id;
  
  INSERT INTO accesos (
    Id_Usuario, 
   	Tipo_Acceso,
   	Id_Fuente,
   	Latitud,
    Longitud)
   VALUES (
       @id,
       "LOGOUT",
       @disp,
       @lat,
       @lng
   );
        
  #Segundo: se retorna el resultado
  SELECT
   ('TRUE') AS status,
   ('Sesion finalizada')AS msj;
    
ELSE
   SELECT 
    ('FALSE') AS status,
    ('Nombre de usuario incorrecto') AS msj;
END IF;


ELSE
SELECT 
    (FALSE) AS status,
    ('Fuente no autorizada') AS msj;
END IF;

END$$

--
-- Funciones
--
CREATE DEFINER=`root`@`localhost` FUNCTION `change_pass_x_nick` (`_nick` VARCHAR(50), `_pass` VARCHAR(50)) RETURNS VARCHAR(20) CHARSET utf8 COLLATE utf8_spanish_ci BEGIN
SET @id  = NULL;
SET @res = NULL;

SELECT nav.Id_Usuario INTO @id 
FROM navegantes AS nav
WHERE nav.Nick LIKE _nick;

 IF @id IS NULL THEN
   #SET @res = 'FALSE';
   #RETURN @res;
   RETURN '-1';
 ELSE
  SET @@session.block_encryption_mode = 'aes-256-ecb';
  UPDATE navegantes n
   SET n.Pass = AES_ENCRYPT(_pass,@id)
   WHERE n.Id_Usuario = @id;
   #SET @res = 'TRUE';
   #RETURN @res;
   RETURN '1';
 END IF;

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `decrypt_pass_x_nick` (`_nick` VARCHAR(50)) RETURNS VARCHAR(50) CHARSET utf8 COLLATE utf8_spanish_ci BEGIN
 SET @result_pass = NULL;
 SET @@session.block_encryption_mode = 'aes-256-ecb';
 
 SELECT
   AES_DECRYPT(nav.Pass,nav.Id_Usuario) INTO @result_pass
 FROM navegantes as nav 
 WHERE nav.Nick LIKE _nick ;
    
 IF (@result_pass IS NULL )THEN
 	RETURN 'FALSE';
 ELSE   	
    RETURN @result_pass;	
 END IF;

END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `accesos`
--

CREATE TABLE `accesos` (
  `Id_Acceso` bigint(20) UNSIGNED NOT NULL,
  `Id_Usuario` bigint(20) UNSIGNED NOT NULL,
  `Tipo_Acceso` varchar(20) COLLATE utf8_spanish_ci NOT NULL,
  `Fecha` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Id_Fuente` bigint(20) UNSIGNED DEFAULT NULL,
  `Latitud` double DEFAULT NULL,
  `Longitud` double DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `accesos`
--

INSERT INTO `accesos` (`Id_Acceso`, `Id_Usuario`, `Tipo_Acceso`, `Fecha`, `Id_Fuente`, `Latitud`, `Longitud`) VALUES
(1, 1, 'LOGIN', '2022-01-06 16:04:23', 1, 0, 0),
(2, 1, 'LOGOUT', '2022-01-06 16:07:10', 1, 0, 0),
(3, 1, 'LOGIN', '2022-01-15 04:39:37', 1, 0, 0),
(4, 2, 'LOGIN', '2022-01-26 18:25:13', 4, 0, 0),
(5, 2, 'LOGIN', '2022-01-26 18:25:59', 4, 0, 0),
(6, 2, 'LOGIN', '2022-01-26 18:29:39', 4, 0, 0),
(7, 2, 'LOGIN', '2022-01-26 18:30:05', 5, 0, 0),
(8, 2, 'LOGIN', '2022-01-26 18:35:41', 4, 0, 0),
(9, 2, 'LOGIN', '2022-01-26 18:41:59', 4, 0, 0),
(10, 2, 'LOGIN', '2022-01-26 18:42:39', 4, 0, 0),
(11, 2, 'LOGIN', '2022-01-26 18:43:51', 4, 0, 0),
(12, 2, 'LOGIN', '2022-01-26 18:45:08', 4, 0, 0),
(13, 2, 'LOGIN', '2022-01-26 18:46:18', 4, 0, 0),
(14, 2, 'LOGIN', '2022-01-26 18:46:43', 4, 0, 0),
(15, 2, 'LOGIN', '2022-01-26 18:47:12', 4, 0, 0),
(16, 2, 'LOGIN', '2022-01-26 18:47:31', 4, 0, 0),
(17, 2, 'LOGIN', '2022-01-26 18:51:10', 4, 0, 0),
(18, 2, 'LOGIN', '2022-01-26 18:51:45', 4, 0, 0),
(19, 2, 'LOGOUT', '2022-01-26 19:10:16', 4, 0, 0),
(20, 2, 'LOGOUT', '2022-01-26 19:12:27', 4, 0, 0),
(21, 2, 'LOGOUT', '2022-01-26 19:12:40', 4, 0, 0),
(22, 2, 'LOGIN', '2022-01-26 19:16:38', 4, 0, 0),
(23, 2, 'LOGIN', '2022-01-26 19:16:56', 4, 0, 0),
(24, 2, 'LOGOUT', '2022-01-26 19:17:00', 4, 0, 0),
(25, 2, 'LOGIN', '2022-01-26 19:26:36', 4, 0, 0),
(26, 2, 'LOGIN', '2022-02-07 20:01:25', 4, 0, 0),
(27, 1, 'LOGIN', '2022-02-07 20:01:45', 4, 0, 0),
(28, 1, 'LOGIN', '2022-02-07 20:06:20', 4, 0, 0),
(29, 1, 'LOGOUT', '2022-02-07 20:06:27', 4, 0, 0),
(30, 1, 'LOGIN', '2022-02-07 20:08:24', 4, 0, 0),
(31, 1, 'LOGIN', '2022-02-09 18:08:45', 4, 0, 0),
(32, 1, 'LOGOUT', '2022-02-09 18:08:59', 4, 0, 0),
(33, 1, 'LOGIN', '2022-02-15 19:25:22', 4, 0, 0),
(34, 3, 'LOGIN', '2022-02-15 21:05:45', 1, 0, 0),
(35, 3, 'LOGIN', '2022-02-15 21:08:43', 1, 0, 0),
(36, 3, 'LOGIN', '2022-02-15 21:11:39', 1, 0, 0),
(37, 3, 'LOGIN', '2022-02-15 21:12:04', 1, 0, 0),
(38, 3, 'LOGIN', '2022-02-15 21:12:52', 1, 0, 0),
(39, 3, 'LOGIN', '2022-02-15 21:15:19', 1, 0, 0),
(40, 3, 'LOGIN', '2022-02-15 21:19:05', 1, 0, 0),
(41, 3, 'LOGIN', '2022-02-15 21:19:59', 1, 0, 0),
(42, 3, 'LOGIN', '2022-02-15 21:20:04', 1, 0, 0),
(43, 3, 'LOGIN', '2022-02-15 21:21:01', 1, 0, 0),
(44, 3, 'LOGIN', '2022-02-16 14:24:08', 1, 0, 0),
(45, 2, 'LOGIN', '2022-02-16 16:06:51', 1, 0, 0),
(46, 3, 'LOGIN', '2022-02-16 16:32:28', 1, 0, 0),
(47, 3, 'LOGIN', '2022-02-16 16:32:44', 1, 0, 0),
(48, 3, 'LOGIN', '2022-02-16 16:32:56', 1, 0, 0),
(49, 3, 'LOGIN', '2022-02-16 16:37:07', 1, 0, 0),
(50, 3, 'LOGIN', '2022-02-16 16:37:09', 1, 0, 0),
(51, 3, 'LOGIN', '2022-02-16 16:37:25', 1, 0, 0),
(52, 3, 'LOGIN', '2022-02-16 17:37:20', 1, 0, 0),
(53, 3, 'LOGIN', '2022-02-16 17:38:29', 1, 0, 0),
(54, 3, 'LOGIN', '2022-02-16 17:39:08', 1, 0, 0),
(55, 3, 'LOGIN', '2022-02-16 18:09:38', 1, 0, 0),
(56, 3, 'LOGIN', '2022-02-16 18:30:05', 1, 0, 0),
(57, 3, 'LOGIN', '2022-02-16 18:30:37', 1, 0, 0),
(58, 3, 'LOGIN', '2022-02-16 18:37:35', 1, 0, 0),
(59, 3, 'LOGIN', '2022-02-16 18:37:58', 1, 0, 0),
(60, 3, 'LOGIN', '2022-02-16 18:38:23', 1, 0, 0),
(61, 3, 'LOGIN', '2022-02-16 18:39:51', 1, 0, 0),
(62, 3, 'LOGIN', '2022-02-16 18:41:03', 1, 0, 0),
(63, 3, 'LOGIN', '2022-02-16 18:44:19', 1, 0, 0),
(64, 1, 'LOGIN', '2022-02-16 18:47:31', 4, 0, 0),
(65, 3, 'LOGIN', '2022-02-16 18:49:04', 1, 0, 0),
(66, 3, 'LOGIN', '2022-02-16 19:38:40', 1, 0, 0),
(67, 3, 'LOGIN', '2022-02-16 19:43:40', 1, 0, 0),
(68, 3, 'LOGIN', '2022-02-16 20:18:23', 1, 0, 0);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `fuentes`
--

CREATE TABLE `fuentes` (
  `Id_Fuente` bigint(20) UNSIGNED NOT NULL,
  `Fuente` varchar(50) COLLATE utf8_spanish_ci DEFAULT NULL,
  `UCrea` bigint(20) UNSIGNED DEFAULT NULL,
  `FCrea` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `UAct` bigint(20) UNSIGNED DEFAULT NULL,
  `FAct` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `fuentes`
--

INSERT INTO `fuentes` (`Id_Fuente`, `Fuente`, `UCrea`, `FCrea`, `UAct`, `FAct`) VALUES
(1, 'WEB', 1, '2022-02-16 14:03:07', 1, '2022-02-16 14:03:20'),
(2, 'TABLETA', 1, '2022-02-16 14:03:07', 1, '2022-02-16 14:03:21'),
(3, 'CELULAR', 1, '2022-02-16 14:03:07', 1, '2022-02-16 14:03:23'),
(4, 'POSTMAN', 1, '2022-02-16 14:09:41', 1, '2022-02-16 14:09:52'),
(5, 'BD', 1, '2022-02-16 14:09:41', 1, '2022-02-16 14:09:55');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `links`
--

CREATE TABLE `links` (
  `Id_Link` bigint(20) UNSIGNED NOT NULL,
  `Id_Usuario` bigint(20) UNSIGNED NOT NULL,
  `Id_Modulo` bigint(20) UNSIGNED NOT NULL,
  `Principal` tinyint(1) DEFAULT '0',
  `Escritura` tinyint(1) DEFAULT '0',
  `Id_Fuente` bigint(20) UNSIGNED DEFAULT NULL,
  `UCrea` bigint(20) UNSIGNED NOT NULL,
  `FCrea` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UAct` bigint(20) UNSIGNED DEFAULT NULL,
  `FAct` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `links`
--

INSERT INTO `links` (`Id_Link`, `Id_Usuario`, `Id_Modulo`, `Principal`, `Escritura`, `Id_Fuente`, `UCrea`, `FCrea`, `UAct`, `FAct`) VALUES
(2, 2, 2, NULL, 0, 1, 1, '2022-01-06 16:24:47', NULL, '2022-02-16 14:13:22'),
(3, 3, 3, 1, 1, 1, 1, '2022-01-06 16:24:47', NULL, '2022-02-16 16:47:42'),
(5, 2, 3, NULL, 0, 1, 1, '2022-02-03 19:52:50', NULL, '2022-02-16 14:13:29');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `modulos`
--

CREATE TABLE `modulos` (
  `Id_Modulo` bigint(20) UNSIGNED NOT NULL,
  `Modulo` varchar(100) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Ruta` varchar(255) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Grupo` bigint(20) UNSIGNED DEFAULT NULL,
  `UCrea` bigint(20) UNSIGNED NOT NULL,
  `FCrea` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UAct` bigint(20) UNSIGNED DEFAULT NULL,
  `FAct` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `modulos`
--

INSERT INTO `modulos` (`Id_Modulo`, `Modulo`, `Ruta`, `Grupo`, `UCrea`, `FCrea`, `UAct`, `FAct`) VALUES
(1, 'Usuarios', 'nauta.test/navegantes/usuarios/', 1, 1, '2022-01-06 16:23:38', NULL, '2022-01-06 16:23:38'),
(2, 'Captura_Supervision', 'nauta.test/captura/supervision', 2, 1, '2022-01-06 16:23:38', NULL, '2022-01-06 16:23:38'),
(3, 'Captura_capturista', '/web/vistas/usuarios/usuarios_lst.html', 2, 1, '2022-01-06 16:23:38', 1, '2022-02-16 17:38:50');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `modulos_grupo`
--

CREATE TABLE `modulos_grupo` (
  `Id_Grupo` bigint(20) UNSIGNED NOT NULL,
  `Grupo` varchar(50) COLLATE utf8_spanish_ci NOT NULL,
  `UCrea` bigint(20) UNSIGNED NOT NULL,
  `FCrea` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UAct` bigint(20) UNSIGNED DEFAULT NULL,
  `FAct` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `modulos_grupo`
--

INSERT INTO `modulos_grupo` (`Id_Grupo`, `Grupo`, `UCrea`, `FCrea`, `UAct`, `FAct`) VALUES
(1, 'DESARROLLO', 1, '2022-01-06 16:13:20', NULL, '2022-01-06 16:13:20'),
(2, 'UNIDAD_CAPTURA', 1, '2022-01-06 16:13:20', NULL, '2022-01-06 16:13:20'),
(9, 'UNIDAD_SUPERVISION', 1, '2022-01-21 17:38:16', NULL, '2022-01-21 17:38:16');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `multimedia`
--

CREATE TABLE `multimedia` (
  `Id` bigint(20) UNSIGNED NOT NULL,
  `Tipo_archivo` varchar(50) COLLATE utf8_spanish_ci DEFAULT NULL COMMENT 'Imagen, HDigital',
  `Nombre` varchar(100) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Ruta` varchar(255) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Vista_previa` varchar(255) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Arch_binario` longblob,
  `Tabla` varchar(100) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Tabla_Id` varchar(100) COLLATE utf8_spanish_ci DEFAULT NULL,
  `UCrea` bigint(20) UNSIGNED DEFAULT NULL,
  `FCrea` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `UAct` bigint(20) UNSIGNED DEFAULT NULL,
  `FAct` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `multimedia`
--

INSERT INTO `multimedia` (`Id`, `Tipo_archivo`, `Nombre`, `Ruta`, `Vista_previa`, `Arch_binario`, `Tabla`, `Tabla_Id`, `UCrea`, `FCrea`, `UAct`, `FAct`) VALUES
(3, 'PERFIL', '3-perfil', 'C:/laragon/www/sau/multimedia/3/3-perfil.jpg', 'sau.test/multimedia/3/3-perfil.jpg', NULL, 'navegantes', '3', 1, '2022-02-03 19:20:18', NULL, '2022-02-16 20:17:11');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `navegantes`
--

CREATE TABLE `navegantes` (
  `Id_Usuario` bigint(20) UNSIGNED NOT NULL,
  `Paterno` varchar(50) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Materno` varchar(50) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Nombre` varchar(50) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Nick` varchar(50) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Pass` blob,
  `Nivel` varchar(50) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Activo` tinyint(1) DEFAULT '1',
  `EnLinea` tinyint(1) DEFAULT '-1',
  `Token` varchar(40) COLLATE utf8_spanish_ci DEFAULT NULL,
  `UCrea` bigint(20) UNSIGNED DEFAULT NULL,
  `FCrea` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `UAct` bigint(20) UNSIGNED DEFAULT NULL,
  `FAct` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `navegantes`
--

INSERT INTO `navegantes` (`Id_Usuario`, `Paterno`, `Materno`, `Nombre`, `Nick`, `Pass`, `Nivel`, `Activo`, `EnLinea`, `Token`, `UCrea`, `FCrea`, `UAct`, `FAct`) VALUES
(1, 'P', 'm', 'n', 'ni', 0x761b98b34eb8babe02675d505e78892e, 'DEVELOPER', 1, 1, 'bfd12f0c5442bb43e179adec86bdfe7f2fa488ef', NULL, '2022-01-06 01:35:31', NULL, '2022-02-16 18:47:31'),
(2, 'P2', 'm2', 'n2', 'ni2', 0x11561e9a351f92cdfe7744c79d0dcd49, 'SUPERVISOR_CAPTURA', 1, 1, '4bc85200ec4a8566d5bfeeb78d5e073bcce372b6', NULL, '2022-01-06 01:35:43', NULL, '2022-02-16 16:06:51'),
(3, 'P3', 'm3', 'n3', 'ni3', 0xcc808b3be1398e2f86b0279b664c8af9, 'CAPTURISTA', 1, -1, NULL, NULL, '2022-01-06 01:35:54', NULL, '2022-02-16 20:43:10'),
(14, 'Prueba', 'Crear', 'Usuario', 'TEST', 0xbf092c1a8bdaa53ee5ba49a5082087f6, NULL, 1, -1, NULL, NULL, '2022-02-03 18:59:17', NULL, '2022-02-09 18:08:30');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `navegantes_fuentes`
--

CREATE TABLE `navegantes_fuentes` (
  `Id_NavF` bigint(20) UNSIGNED NOT NULL,
  `Id_Navegante` bigint(20) UNSIGNED DEFAULT NULL,
  `Id_Fuente` bigint(20) UNSIGNED DEFAULT NULL,
  `UCrea` bigint(20) UNSIGNED DEFAULT NULL,
  `FCrea` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `UAct` bigint(20) UNSIGNED DEFAULT NULL,
  `FAct` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `navegantes_niveles`
--

CREATE TABLE `navegantes_niveles` (
  `Id_UNivel` varchar(50) COLLATE utf8_spanish_ci NOT NULL,
  `UCrea` bigint(20) UNSIGNED NOT NULL,
  `FCrea` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UAct` bigint(20) UNSIGNED DEFAULT NULL,
  `FAct` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `navegantes_niveles`
--

INSERT INTO `navegantes_niveles` (`Id_UNivel`, `UCrea`, `FCrea`, `UAct`, `FAct`) VALUES
('CAPTURISTA', 1, '2022-01-06 16:11:11', NULL, '2022-01-06 16:11:11'),
('DEVELOPER', 1, '2022-01-06 16:11:11', NULL, '2022-01-06 16:11:11'),
('SUPERVISOR_CAPTURA', 1, '2022-01-06 16:11:11', NULL, '2022-01-06 16:11:11');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `accesos`
--
ALTER TABLE `accesos`
  ADD PRIMARY KEY (`Id_Acceso`),
  ADD KEY `fk_usuario_acc` (`Id_Usuario`),
  ADD KEY `fk_fuente_acc` (`Id_Fuente`);

--
-- Indices de la tabla `fuentes`
--
ALTER TABLE `fuentes`
  ADD PRIMARY KEY (`Id_Fuente`),
  ADD UNIQUE KEY `Fuente` (`Fuente`),
  ADD KEY `fk_uact_fnte` (`UAct`),
  ADD KEY `fk_ucea_fnte` (`UCrea`);

--
-- Indices de la tabla `links`
--
ALTER TABLE `links`
  ADD PRIMARY KEY (`Id_Link`),
  ADD KEY `fk_usuario_link` (`Id_Usuario`),
  ADD KEY `fk_modulo_link` (`Id_Modulo`),
  ADD KEY `fk_ucrea_link` (`UCrea`),
  ADD KEY `fk_uact_link` (`UAct`),
  ADD KEY `fk_dispositivos_link` (`Id_Fuente`);

--
-- Indices de la tabla `modulos`
--
ALTER TABLE `modulos`
  ADD PRIMARY KEY (`Id_Modulo`),
  ADD KEY `fk_ucrea_mod` (`UCrea`),
  ADD KEY `fk_uact_mod` (`UAct`),
  ADD KEY `Grupo` (`Grupo`);

--
-- Indices de la tabla `modulos_grupo`
--
ALTER TABLE `modulos_grupo`
  ADD PRIMARY KEY (`Id_Grupo`),
  ADD UNIQUE KEY `Grupo` (`Grupo`),
  ADD KEY `fk_ucrea_gpo` (`UCrea`),
  ADD KEY `fk_uact_gpo` (`UAct`);

--
-- Indices de la tabla `multimedia`
--
ALTER TABLE `multimedia`
  ADD PRIMARY KEY (`Id`),
  ADD UNIQUE KEY `Nombre` (`Nombre`),
  ADD KEY `fk_ucrea_mm` (`UCrea`),
  ADD KEY `fk_uact_mm` (`UAct`);

--
-- Indices de la tabla `navegantes`
--
ALTER TABLE `navegantes`
  ADD PRIMARY KEY (`Id_Usuario`),
  ADD UNIQUE KEY `Nick` (`Nick`),
  ADD UNIQUE KEY `Token` (`Token`),
  ADD KEY `Nivel` (`Nivel`),
  ADD KEY `Status` (`Activo`);

--
-- Indices de la tabla `navegantes_fuentes`
--
ALTER TABLE `navegantes_fuentes`
  ADD PRIMARY KEY (`Id_NavF`),
  ADD KEY `fk_ucrea_nvf` (`UCrea`),
  ADD KEY `fk_uact_nvf` (`UAct`),
  ADD KEY `fk_fuente_nvf` (`Id_Fuente`),
  ADD KEY `fk_navegante_nvf` (`Id_Navegante`);

--
-- Indices de la tabla `navegantes_niveles`
--
ALTER TABLE `navegantes_niveles`
  ADD PRIMARY KEY (`Id_UNivel`),
  ADD KEY `UAct` (`UAct`),
  ADD KEY `UCrea` (`UCrea`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `accesos`
--
ALTER TABLE `accesos`
  MODIFY `Id_Acceso` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=69;

--
-- AUTO_INCREMENT de la tabla `fuentes`
--
ALTER TABLE `fuentes`
  MODIFY `Id_Fuente` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `links`
--
ALTER TABLE `links`
  MODIFY `Id_Link` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `modulos`
--
ALTER TABLE `modulos`
  MODIFY `Id_Modulo` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `modulos_grupo`
--
ALTER TABLE `modulos_grupo`
  MODIFY `Id_Grupo` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT de la tabla `multimedia`
--
ALTER TABLE `multimedia`
  MODIFY `Id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `navegantes`
--
ALTER TABLE `navegantes`
  MODIFY `Id_Usuario` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT de la tabla `navegantes_fuentes`
--
ALTER TABLE `navegantes_fuentes`
  MODIFY `Id_NavF` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `accesos`
--
ALTER TABLE `accesos`
  ADD CONSTRAINT `fk_fuente_acc` FOREIGN KEY (`Id_Fuente`) REFERENCES `fuentes` (`Id_Fuente`) ON DELETE NO ACTION ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_usuario_acc` FOREIGN KEY (`Id_Usuario`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `fuentes`
--
ALTER TABLE `fuentes`
  ADD CONSTRAINT `fk_uact_fnte` FOREIGN KEY (`UAct`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ucea_fnte` FOREIGN KEY (`UCrea`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Filtros para la tabla `links`
--
ALTER TABLE `links`
  ADD CONSTRAINT `fk_dispositivos_link` FOREIGN KEY (`Id_Fuente`) REFERENCES `fuentes` (`Id_Fuente`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_modulo_link` FOREIGN KEY (`Id_Modulo`) REFERENCES `modulos` (`Id_Modulo`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_uact_link` FOREIGN KEY (`UAct`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE NO ACTION ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ucrea_link` FOREIGN KEY (`UCrea`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE NO ACTION ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_usuario_link` FOREIGN KEY (`Id_Usuario`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `modulos`
--
ALTER TABLE `modulos`
  ADD CONSTRAINT `fk_grupo_mod` FOREIGN KEY (`Grupo`) REFERENCES `modulos_grupo` (`Id_Grupo`) ON DELETE NO ACTION ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_uact_mod` FOREIGN KEY (`UAct`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE NO ACTION ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ucrea_mod` FOREIGN KEY (`UCrea`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `modulos_grupo`
--
ALTER TABLE `modulos_grupo`
  ADD CONSTRAINT `fk_uact_gpo` FOREIGN KEY (`UAct`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE NO ACTION ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ucrea_gpo` FOREIGN KEY (`UCrea`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `multimedia`
--
ALTER TABLE `multimedia`
  ADD CONSTRAINT `fk_uact_mm` FOREIGN KEY (`UAct`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ucrea_mm` FOREIGN KEY (`UCrea`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Filtros para la tabla `navegantes_fuentes`
--
ALTER TABLE `navegantes_fuentes`
  ADD CONSTRAINT `fk_fuente_nvf` FOREIGN KEY (`Id_Fuente`) REFERENCES `fuentes` (`Id_Fuente`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_navegante_nvf` FOREIGN KEY (`Id_Navegante`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_uact_nvf` FOREIGN KEY (`UAct`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ucrea_nvf` FOREIGN KEY (`UCrea`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Filtros para la tabla `navegantes_niveles`
--
ALTER TABLE `navegantes_niveles`
  ADD CONSTRAINT `fk_uact_univeles` FOREIGN KEY (`UAct`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE NO ACTION ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ucrea_univeles` FOREIGN KEY (`UCrea`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE NO ACTION ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
