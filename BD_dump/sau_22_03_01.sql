-- phpMyAdmin SQL Dump
-- version 5.1.1
-- https://www.phpmyadmin.net/
--
-- Servidor: localhost:3306
-- Tiempo de generación: 01-03-2022 a las 20:36:48
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
CREATE  PROCEDURE `checkuser` (IN `_nick` VARCHAR(50), IN `_token` VARCHAR(40))  NO SQL
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

CREATE  PROCEDURE `inserta_usuario` (IN `_pat` VARCHAR(50), IN `_mat` VARCHAR(50), IN `_nom` VARCHAR(50), IN `_nick` VARCHAR(50), IN `_pass` VARCHAR(50))  NO SQL
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

CREATE  PROCEDURE `login` (IN `_nick` VARCHAR(50), IN `_pass` VARCHAR(50), IN `_disp` VARCHAR(50), IN `_lat` VARCHAR(50), IN `_lng` VARCHAR(50))  BEGIN
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

CREATE  PROCEDURE `logout` (IN `_nick` VARCHAR(50), IN `_disp` VARCHAR(30), IN `_lat` VARCHAR(50), IN `_lng` VARCHAR(50))  BEGIN
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
CREATE  FUNCTION `change_pass_x_nick` (`_nick` VARCHAR(50), `_pass` VARCHAR(50)) RETURNS VARCHAR(20) CHARSET utf8 COLLATE utf8_spanish_ci BEGIN
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

CREATE  FUNCTION `decrypt_pass_x_nick` (`_nick` VARCHAR(50)) RETURNS VARCHAR(50) CHARSET utf8 COLLATE utf8_spanish_ci BEGIN
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
(68, 3, 'LOGIN', '2022-02-16 20:18:23', 1, 0, 0),
(69, 3, 'LOGOUT', '2022-02-16 20:51:09', 1, 0, 0),
(70, 3, 'LOGOUT', '2022-02-16 20:51:27', 1, 0, 0),
(71, 3, 'LOGOUT', '2022-02-16 20:53:43', 1, 0, 0),
(72, 3, 'LOGOUT', '2022-02-16 20:54:06', 1, 0, 0),
(73, 3, 'LOGOUT', '2022-02-16 20:54:14', 1, 0, 0),
(74, 3, 'LOGOUT', '2022-02-16 20:54:30', 1, 0, 0),
(75, 3, 'LOGIN', '2022-02-16 20:54:47', 1, 0, 0),
(76, 3, 'LOGOUT', '2022-02-16 20:54:50', 1, 0, 0),
(77, 3, 'LOGIN', '2022-02-17 15:35:21', 1, 0, 0),
(78, 3, 'LOGIN', '2022-02-18 13:52:22', 1, 0, 0),
(79, 3, 'LOGIN', '2022-02-21 17:41:09', 1, 0, 0),
(80, 3, 'LOGIN', '2022-02-22 13:11:48', 1, 0, 0),
(81, 3, 'LOGIN', '2022-02-22 21:03:44', 1, 0, 0),
(82, 3, 'LOGIN', '2022-02-23 13:14:11', 1, 0, 0),
(83, 3, 'LOGIN', '2022-02-25 14:33:12', 1, 0, 0),
(84, 3, 'LOGIN', '2022-02-25 19:27:22', 1, 0, 0),
(85, 3, 'LOGIN', '2022-02-25 19:42:50', 1, 0, 0),
(86, 3, 'LOGIN', '2022-02-25 19:44:34', 1, 0, 0),
(87, 3, 'LOGIN', '2022-02-25 19:50:38', 1, 0, 0),
(88, 3, 'LOGIN', '2022-02-25 19:56:27', 1, 0, 0),
(89, 3, 'LOGIN', '2022-02-28 14:38:54', 1, 0, 0),
(90, 3, 'LOGIN', '2022-02-28 14:51:37', 1, 0, 0),
(91, 3, 'LOGOUT', '2022-02-28 19:43:53', 1, 0, 0),
(92, 1, 'LOGIN', '2022-02-28 19:46:25', 1, 0, 0),
(93, 1, 'LOGOUT', '2022-02-28 20:43:18', 1, 0, 0),
(94, 3, 'LOGIN', '2022-02-28 20:43:21', 1, 0, 0),
(95, 3, 'LOGIN', '2022-03-01 13:24:56', 1, 0, 0),
(96, 3, 'LOGIN', '2022-03-01 18:35:31', 1, 0, 0);

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
(2, 1, 1, 1, 0, 1, 1, '2022-01-06 16:24:47', NULL, '2022-02-28 19:46:18'),
(3, 3, 3, NULL, 1, 1, 1, '2022-01-06 16:24:47', NULL, '2022-02-25 19:42:28'),
(5, 2, 3, NULL, 0, 1, 1, '2022-02-03 19:52:50', NULL, '2022-02-16 14:13:29'),
(6, 3, 4, NULL, 1, 1, 1, '2022-02-25 19:42:11', NULL, '2022-02-28 14:51:21'),
(7, 3, 5, 1, 1, 1, 1, '2022-02-28 14:51:14', 1, '2022-02-28 14:51:14');

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
(1, 'Usuarios', '/web/vistas/usuarios/usuarios_lst.html', 1, 1, '2022-01-06 16:23:38', NULL, '2022-02-28 19:45:57'),
(2, 'Captura_Supervision', 'nauta.test/captura/supervision', 2, 1, '2022-01-06 16:23:38', NULL, '2022-01-06 16:23:38'),
(3, 'Captura_capturista', '/web/vistas/usuarios/usuarios_lst.html', 2, 1, '2022-01-06 16:23:38', 1, '2022-02-16 17:38:50'),
(4, 'Proveedores_tipo_giro\r\n', '/web/vistas/proveedores_tipo_giro/proveedores_tipo_giro_lst.html', 10, 1, '2022-02-25 19:40:44', NULL, '2022-02-28 20:47:33'),
(5, 'Dash_admin', '/web/vistas/dash_admin/dash_admin.html', 1, 1, '2022-02-28 14:50:50', 1, '2022-02-28 14:50:50'),
(6, 'Proveedores', '/web/vistas/proveedores/proveedores_lst.html', 10, 1, '2022-02-28 20:48:28', 1, '2022-02-28 20:48:28');

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
(9, 'UNIDAD_SUPERVISION', 1, '2022-01-21 17:38:16', NULL, '2022-01-21 17:38:16'),
(10, 'Proveedores', 1, '2022-02-25 19:39:15', NULL, '2022-02-28 14:48:51');

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
(3, 'PERFIL', '3-perfil', 'C:/laragon/www/sau/multimedia/3/3-perfil.jpg', 'sau.test/multimedia/3/3-perfil.jpg', NULL, 'navegantes', '3', 3, '2022-02-03 19:20:18', NULL, '2022-02-25 16:32:17'),
(4, 'PERFIL', '14-perfil', 'C:/laragon/www/sau/multimedia/14/14-perfil.jpg', 'sau.test/multimedia/14/14-perfil.jpg', NULL, 'navegantes', '14', 3, '2022-02-25 15:34:47', NULL, '2022-02-25 16:32:17'),
(5, 'PERFIL', '2-perfil', 'C:/laragon/www/sau/multimedia/2/2-perfil.jpg', 'sau.test/multimedia/2/2-perfil.jpg', NULL, 'navegantes', '2', 3, '2022-02-25 16:32:51', NULL, '2022-02-25 16:32:51'),
(6, 'PERFIL', '1-perfil', 'C:/laragon/www/remmex/multimedia/1/1-perfil.jpg', 'remmex.test/multimedia/1/1-perfil.jpg', NULL, 'navegantes', '1', 3, '2022-02-25 16:33:10', NULL, '2022-02-25 19:27:54');

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
(1, 'P', 'm', 'n', 'ni', 0x761b98b34eb8babe02675d505e78892e, 'DEVELOPER', 1, -1, NULL, NULL, '2022-01-06 01:35:31', NULL, '2022-02-28 20:43:18'),
(2, 'P2', 'm2', 'n2', 'ni2', 0x11561e9a351f92cdfe7744c79d0dcd49, 'SUPERVISOR_CAPTURA', 1, 1, '4bc85200ec4a8566d5bfeeb78d5e073bcce372b6', NULL, '2022-01-06 01:35:43', NULL, '2022-02-16 16:06:51'),
(3, 'P3', 'm3', 'n3', 'ni3', 0xcc808b3be1398e2f86b0279b664c8af9, 'CAPTURISTA', 1, 1, 'e2c30b4d709dd3feb9680d9b62da96f80338b4f3', NULL, '2022-01-06 01:35:54', NULL, '2022-03-01 18:35:31'),
(14, 'Pelaez', 'Becerril', 'Irek', 'IrekPB', 0xbf092c1a8bdaa53ee5ba49a5082087f6, 'CAPTURISTA', 1, 1, NULL, NULL, '2022-02-03 18:59:17', 1, '2022-02-28 20:24:32');

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

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos`
--

CREATE TABLE `productos` (
  `Id_Producto` bigint(20) UNSIGNED NOT NULL,
  `Codigo_prod` varchar(30) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Tipo` bigint(20) UNSIGNED DEFAULT NULL,
  `Nombre_prod` varchar(100) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Caracteristicas` text COLLATE utf8_spanish_ci,
  `Precio` double DEFAULT NULL,
  `Descuento` double DEFAULT NULL,
  `Cantidad_prod` bigint(20) UNSIGNED DEFAULT NULL,
  `Unidad_medida` varchar(30) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Stock_minimo` bigint(20) UNSIGNED DEFAULT NULL,
  `Activo` tinyint(1) DEFAULT NULL,
  `Ubicacion` varchar(50) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Cliente` bigint(20) UNSIGNED DEFAULT NULL,
  `Vendedor` bigint(20) UNSIGNED DEFAULT NULL,
  `CodigoQR` varchar(255) COLLATE utf8_spanish_ci DEFAULT NULL,
  `UCrea` bigint(20) UNSIGNED DEFAULT NULL,
  `FCrea` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `UAct` bigint(20) UNSIGNED DEFAULT NULL,
  `FAct` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `productos`
--

INSERT INTO `productos` (`Id_Producto`, `Codigo_prod`, `Tipo`, `Nombre_prod`, `Caracteristicas`, `Precio`, `Descuento`, `Cantidad_prod`, `Unidad_medida`, `Stock_minimo`, `Activo`, `Ubicacion`, `Cliente`, `Vendedor`, `CodigoQR`, `UCrea`, `FCrea`, `UAct`, `FAct`) VALUES
(1, 'A- 1', 3, 'A- 1', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(2, 'A- 2', 3, 'A- 2', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(3, 'A -3', 3, 'A- 3', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(4, 'A- 4', 3, 'A- 4', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(5, 'A- 5', 3, 'A- 5', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(6, 'A- 6', 3, 'A- 6', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(7, 'A- 7', 3, 'A- 7', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(8, 'A- 8', 3, 'A- 8', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(9, 'A- 9', 3, 'A- 9', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(10, 'A- 10', 3, 'A- 10', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(11, 'A- 11', 3, 'A- 11', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(12, 'A- 12', 3, 'A- 12', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(13, 'A- 13', 3, 'A- 13', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(14, 'A- 14', 3, 'A- 14', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(15, 'A- 15', 3, 'A- 15', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(16, 'A- 16', 3, 'A- 16', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(17, 'A- 17', 3, 'A- 17', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(18, 'A- 18', 3, 'A- 18', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(19, 'A- 19', 3, 'A- 19', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(20, 'A- 20', 3, 'A- 20', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(21, 'A- 21', 3, 'A- 21', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(22, 'A- 22', 3, 'A- 22', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(23, 'A- 23', 3, 'A- 23', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(24, 'A- 24', 3, 'A- 24', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(25, 'A- 25', 3, 'A- 25', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(26, 'A- 26', 3, 'A- 26', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(27, 'A- 27', 3, 'A- 27', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(28, 'A- 28', 3, 'A- 28', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(29, 'A- 29', 3, 'A- 29', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(30, 'A- 30', 3, 'A- 30', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(31, 'A- 31', 3, 'A- 31', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(32, 'A- 32', 3, 'A- 32', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(33, 'A- 33', 3, 'A- 33', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(34, 'A- 34', 3, 'A- 34', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(35, 'A- 35', 3, 'A- 35', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(36, 'A- 36', 3, 'A- 36', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(37, 'A- 37', 3, 'A- 37', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(38, 'A- 38', 3, 'A- 38', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(39, 'A- 39', 3, 'A- 39', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(40, 'A- 40', 3, 'A- 40', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(41, 'A- 41', 3, 'A- 41', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(42, 'A- 42', 3, 'A- 42', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(43, 'A- 43', 3, 'A- 43', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(44, 'A- 44', 3, 'A- 44', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(45, 'A- 45', 3, 'A- 45', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(46, 'A- 46', 3, 'A- 46', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(47, 'A- 47', 3, 'A- 47', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(48, 'A- 48', 3, 'A- 48', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(49, 'A- 49', 3, 'A- 49', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(50, 'A- 50', 3, 'A- 50', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(51, 'B- 1', 3, 'B- 1', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(52, 'B- 2', 3, 'B- 2', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(53, 'B- 3', 3, 'B- 3', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(54, 'B- 4', 3, 'B- 4', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(55, 'B- 5', 3, 'B- 5', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(56, 'B- 6', 3, 'B- 6', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(57, 'B- 7', 3, 'B- 7', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(58, 'B- 8', 3, 'B- 8', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(59, 'B- 9', 3, 'B- 9', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(60, 'B- 10', 3, 'B- 10', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(61, 'B- 11', 3, 'B- 11', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(62, 'B- 12', 3, 'B- 12', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(63, 'B- 13', 3, 'B- 13', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(64, 'B- 14', 3, 'B- 14', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(65, 'B- 15', 3, 'B- 15', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(66, 'B- 16', 3, 'B- 16', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(67, 'B- 17', 3, 'B- 17', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(68, 'B- 18', 3, 'B- 18', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(69, 'B- 19', 3, 'B- 19', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(70, 'B- 20', 3, 'B- 20', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(71, 'B- 21', 3, 'B- 21', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(72, 'B- 22', 3, 'B- 22', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(73, 'B- 23', 3, 'B- 23', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(74, 'B- 24', 3, 'B- 24', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(75, 'B- 25', 3, 'B- 25', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(76, 'B- 26', 3, 'B- 26', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(77, 'B- 27', 3, 'B- 27', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(78, 'B- 28', 3, 'B- 28', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(79, 'B- 29', 3, 'B- 29', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(80, 'B- 30', 3, 'B- 30', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(81, 'B- 31', 3, 'B- 31', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(82, 'B- 32', 3, 'B- 32', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(83, 'B- 33', 3, 'B- 33', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(84, 'B- 34', 3, 'B- 34', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(85, 'B- 35', 3, 'B- 35', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(86, 'B- 36', 3, 'B- 36', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(87, 'B- 37', 3, 'B- 37', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(88, 'B- 38', 3, 'B- 38', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(89, 'B- 39', 3, 'B- 39', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(90, 'B- 40', 3, 'B- 40', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(91, 'B- 41', 3, 'B- 41', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(92, 'B- 42', 3, 'B- 42', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(93, 'B- 43', 3, 'B- 43', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(94, 'B- 44', 3, 'B- 44', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(95, 'B- 45', 3, 'B- 45', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(96, 'B- 46', 3, 'B- 46', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(97, 'B- 47', 3, 'B- 47', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(98, 'B- 48', 3, 'B- 48', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(99, 'B- 49', 3, 'B- 49', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(100, 'B- 50', 3, 'B- 50', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(101, 'C- 1', 3, 'C- 1', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(102, 'C- 2', 3, 'C- 2', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(103, 'C- 3', 3, 'C- 3', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(104, 'C- 4', 3, 'C- 4', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(105, 'C- 5', 3, 'C- 5', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(106, 'C- 6', 3, 'C- 6', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(107, 'C- 7', 3, 'C- 7', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(108, 'C- 8', 3, 'C- 8', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(109, 'C- 9', 3, 'C- 9', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(110, 'C- 10', 3, 'C- 10', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(111, 'C- 11', 3, 'C- 11', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(112, 'C- 12', 3, 'C- 12', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(113, 'C- 13', 3, 'C- 13', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(114, 'C- 14', 3, 'C- 14', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(115, 'C- 15', 3, 'C- 15', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(116, 'C- 16', 3, 'C- 16', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(117, 'C- 17', 3, 'C- 17', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(118, 'C- 18', 3, 'C- 18', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(119, 'C- 19', 3, 'C- 19', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(120, 'C- 20', 3, 'C- 20', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(121, 'C- 21', 3, 'C- 21', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(122, 'C- 22', 3, 'C- 22', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(123, 'C- 23', 3, 'C- 23', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(124, 'C- 24', 3, 'C- 24', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(125, 'C- 25', 3, 'C- 25', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(126, 'C- 26', 3, 'C- 26', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(127, 'C- 27', 3, 'C- 27', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(128, 'C- 28', 3, 'C- 28', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(129, 'C- 29', 3, 'C- 29', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(130, 'C- 30', 3, 'C- 30', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(131, 'C- 31', 3, 'C- 31', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(132, 'C- 32', 3, 'C- 32', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(133, 'C- 33', 3, 'C- 33', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(134, 'C- 34', 3, 'C- 34', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(135, 'C- 35', 3, 'C- 35', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(136, 'C- 36', 3, 'C- 36', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(137, 'C- 37', 3, 'C- 37', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(138, 'C- 38', 3, 'C- 38', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(139, 'C- 39', 3, 'C- 39', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(140, 'C- 40', 3, 'C- 40', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(141, 'C- 41', 3, 'C- 41', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(142, 'C- 42', 3, 'C- 42', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(143, 'C- 43', 3, 'C- 43', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(144, 'C- 44', 3, 'C- 44', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(145, 'C- 45', 3, 'C- 45', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(146, 'C- 46', 3, 'C- 46', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(147, 'C- 47', 3, 'C- 47', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(148, 'C- 48', 3, 'C- 48', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(149, 'C- 49', 3, 'C- 49', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(150, 'C- 50', 3, 'C- 50', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(151, 'E- 1', 3, 'E- 1', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(152, 'E- 2', 3, 'E- 2', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(153, 'E- 3', 3, 'E- 3', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(154, 'E- 4', 3, 'E- 4', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(155, 'E- 5', 3, 'E- 5', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(156, 'E- 6', 3, 'E- 6', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(157, 'E- 7', 3, 'E- 7', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(158, 'E- 8', 3, 'E- 8', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(159, 'E- 9', 3, 'E- 9', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(160, 'E- 10', 3, 'E- 10', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(161, 'E- 11', 3, 'E- 11', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(162, 'E- 12', 3, 'E- 12', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(163, 'E- 13', 3, 'E- 13', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(164, 'E- 14', 3, 'E- 14', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(165, 'E- 15', 3, 'E- 15', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(166, 'E- 16', 3, 'E- 16', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(167, 'E- 17', 3, 'E- 17', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(168, 'E- 18', 3, 'E- 18', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(169, 'E- 19', 3, 'E- 19', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(170, 'E- 20', 3, 'E- 20', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(171, 'E- 21', 3, 'E- 21', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(172, 'E- 22', 3, 'E- 22', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(173, 'E- 23', 3, 'E- 23', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(174, 'E- 24', 3, 'E- 24', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(175, 'E- 25', 3, 'E- 25', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(176, 'E- 26', 3, 'E- 26', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(177, 'E- 27', 3, 'E- 27', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(178, 'E- 28', 3, 'E- 28', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(179, 'E- 29', 3, 'E- 29', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(180, 'E- 30', 3, 'E- 30', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(181, 'E- 31', 3, 'E- 31', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(182, 'E- 32', 3, 'E- 32', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(183, 'E- 33', 3, 'E- 33', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(184, 'E- 34', 3, 'E- 34', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(185, 'E- 35', 3, 'E- 35', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(186, 'E- 36', 3, 'E- 36', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(187, 'E- 37', 3, 'E- 37', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(188, 'E- 38', 3, 'E- 38', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(189, 'E- 39', 3, 'E- 39', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(190, 'E- 40', 3, 'E- 40', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(191, 'E- 41', 3, 'E- 41', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(192, 'E- 42', 3, 'E- 42', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(193, 'E- 43', 3, 'E- 43', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(194, 'E- 44', 3, 'E- 44', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(195, 'E- 45', 3, 'E- 45', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(196, 'E- 46', 3, 'E- 46', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(197, 'E- 47', 3, 'E- 47', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(198, 'E- 48', 3, 'E- 48', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(199, 'E- 49', 3, 'E- 49', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(200, 'E- 50', 3, 'E- 50', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(201, 'I- 1', 3, 'I- 1', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(202, 'I- 2', 3, 'I- 2', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(203, 'I- 3', 3, 'I- 3', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(204, 'I- 4', 3, 'I- 4', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(205, 'I- 5', 3, 'I- 5', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(206, 'I- 6', 3, 'I- 6', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(207, 'I- 7', 3, 'I- 7', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(208, 'I- 8', 3, 'I- 8', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(209, 'I- 9', 3, 'I- 9', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(210, 'I- 10', 3, 'I- 10', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(211, 'I- 11', 3, 'I- 11', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(212, 'I- 12', 3, 'I- 12', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(213, 'I- 13', 3, 'I- 13', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(214, 'I- 14', 3, 'I- 14', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(215, 'I- 15', 3, 'I- 15', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(216, 'I- 16', 3, 'I- 16', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(217, 'I- 17', 3, 'I- 17', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(218, 'I- 18', 3, 'I- 18', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(219, 'I- 19', 3, 'I- 19', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(220, 'I- 20', 3, 'I- 20', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(221, 'I- 21', 3, 'I- 21', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(222, 'I- 22', 3, 'I- 22', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(223, 'I- 23', 3, 'I- 23', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(224, 'I- 24', 3, 'I- 24', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(225, 'I- 25', 3, 'I- 25', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(226, 'I- 26', 3, 'I- 26', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(227, 'I- 27', 3, 'I- 27', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(228, 'I- 28', 3, 'I- 28', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(229, 'I- 29', 3, 'I- 29', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(230, 'I- 30', 3, 'I- 30', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(231, 'I- 31', 3, 'I- 31', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(232, 'I- 32', 3, 'I- 32', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(233, 'I- 33', 3, 'I- 33', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(234, 'I- 34', 3, 'I- 34', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(235, 'I- 35', 3, 'I- 35', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(236, 'I- 36', 3, 'I- 36', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(237, 'I- 37', 3, 'I- 37', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(238, 'I- 38', 3, 'I- 38', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(239, 'I- 39', 3, 'I- 39', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(240, 'I- 40', 3, 'I- 40', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(241, 'I- 41', 3, 'I- 41', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(242, 'I- 42', 3, 'I- 42', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(243, 'I- 43', 3, 'I- 43', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(244, 'I- 44', 3, 'I- 44', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(245, 'I- 45', 3, 'I- 45', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(246, 'I- 46', 3, 'I- 46', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(247, 'I- 47', 3, 'I- 47', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(248, 'I- 48', 3, 'I- 48', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(249, 'I- 49', 3, 'I- 49', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(250, 'I- 50', 3, 'I- 50', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(251, 'M- 1', 3, 'M- 1', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(252, 'M- 2', 3, 'M- 2', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(253, 'M- 3', 3, 'M- 3', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(254, 'M- 4', 3, 'M- 4', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(255, 'M- 5', 3, 'M- 5', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(256, 'M- 6', 3, 'M- 6', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(257, 'M- 7', 3, 'M- 7', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(258, 'M- 8', 3, 'M- 8', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(259, 'M- 9', 3, 'M- 9', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(260, 'M- 10', 3, 'M- 10', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(261, 'M- 11', 3, 'M- 11', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(262, 'M- 12', 3, 'M- 12', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(263, 'M- 13', 3, 'M- 13', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(264, 'M- 14', 3, 'M- 14', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(265, 'M- 15', 3, 'M- 15', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(266, 'M- 16', 3, 'M- 16', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(267, 'M- 17', 3, 'M- 17', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(268, 'M- 18', 3, 'M- 18', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(269, 'M- 19', 3, 'M- 19', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(270, 'M- 20', 3, 'M- 20', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(271, 'M- 21', 3, 'M- 21', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(272, 'M- 22', 3, 'M- 22', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(273, 'M- 23', 3, 'M- 23', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(274, 'M- 24', 3, 'M- 24', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(275, 'M- 25', 3, 'M- 25', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(276, 'M- 26', 3, 'M- 26', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(277, 'M- 27', 3, 'M- 27', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(278, 'M- 28', 3, 'M- 28', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(279, 'M- 29', 3, 'M- 29', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(280, 'M- 30', 3, 'M- 30', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(281, 'M- 31', 3, 'M- 31', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(282, 'M- 32', 3, 'M- 32', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(283, 'M- 33', 3, 'M- 33', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(284, 'M- 34', 3, 'M- 34', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(285, 'M- 35', 3, 'M- 35', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(286, 'M- 36', 3, 'M- 36', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(287, 'M- 37', 3, 'M- 37', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(288, 'M- 38', 3, 'M- 38', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(289, 'M- 39', 3, 'M- 39', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(290, 'M- 40', 3, 'M- 40', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(291, 'M- 41', 3, 'M- 41', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(292, 'M- 42', 3, 'M- 42', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(293, 'M- 43', 3, 'M- 43', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(294, 'M- 44', 3, 'M- 44', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(295, 'M- 45', 3, 'M- 45', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(296, 'M- 46', 3, 'M- 46', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(297, 'M- 47', 3, 'M- 47', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(298, 'M- 48', 3, 'M- 48', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(299, 'M- 49', 3, 'M- 49', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(300, 'M- 50', 3, 'M- 50', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(301, 'T- 1', 3, 'T- 1', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(302, 'T- 2', 3, 'T- 2', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(303, 'T- 3', 3, 'T- 3', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(304, 'T- 4', 3, 'T- 4', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(305, 'T- 5', 3, 'T- 5', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(306, 'T- 6', 3, 'T- 6', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(307, 'T- 7', 3, 'T- 7', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(308, 'T- 8', 3, 'T- 8', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(309, 'T- 9', 3, 'T- 9', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(310, 'T- 10', 3, 'T- 10', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(311, 'T- 11', 3, 'T- 11', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(312, 'T- 12', 3, 'T- 12', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(313, 'T- 13', 3, 'T- 13', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(314, 'T- 14', 3, 'T- 14', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(315, 'T- 15', 3, 'T- 15', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(316, 'T- 16', 3, 'T- 16', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(317, 'T- 17', 3, 'T- 17', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(318, 'T- 18', 3, 'T- 18', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(319, 'T- 19', 3, 'T- 19', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(320, 'T- 20', 3, 'T- 20', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(321, 'T- 21', 3, 'T- 21', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(322, 'T- 22', 3, 'T- 22', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(323, 'T- 23', 3, 'T- 23', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(324, 'T- 24', 3, 'T- 24', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(325, 'T- 25', 3, 'T- 25', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(326, 'T- 26', 3, 'T- 26', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(327, 'T- 27', 3, 'T- 27', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(328, 'T- 28', 3, 'T- 28', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(329, 'T- 29', 3, 'T- 29', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(330, 'T- 30', 3, 'T- 30', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(331, 'T- 31', 3, 'T- 31', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(332, 'T- 32', 3, 'T- 32', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(333, 'T- 33', 3, 'T- 33', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(334, 'T- 34', 3, 'T- 34', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(335, 'T- 35', 3, 'T- 35', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(336, 'T- 36', 3, 'T- 36', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(337, 'T- 37', 3, 'T- 37', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(338, 'T- 38', 3, 'T- 38', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(339, 'T- 39', 3, 'T- 39', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(340, 'T- 40', 3, 'T- 40', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(341, 'T- 41', 3, 'T- 41', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(342, 'T- 42', 3, 'T- 42', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(343, 'T- 43', 3, 'T- 43', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(344, 'T- 44', 3, 'T- 44', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(345, 'T- 45', 3, 'T- 45', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(346, 'T- 46', 3, 'T- 46', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(347, 'T- 47', 3, 'T- 47', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(348, 'T- 48', 3, 'T- 48', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(349, 'T- 49', 3, 'T- 49', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(350, 'T- 50', 3, 'T- 50', 'EMERGENTE', 0, 0, 1, '1', 1, 1, 'ALMACEN', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(773, 'P0001', 1, 'ADAPTADOR FIJO 1.5\" NST HEMBRA IPT 1.5\" IPT MACHO', NULL, 15, 10, 143, NULL, NULL, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(774, 'P0002', 1, 'ADAPTADOR FIJO', '2.5\" NST HEMBRA IPT 1.5\" IPT MACHO', 12.5, 0, 200, 'Unidad', 145, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(775, 'P0003', 1, 'ADAPTADOR FIJO 2.5\" NST HEMBRA IPT 2.5\" IPT MACHO', NULL, 100, NULL, 24, NULL, NULL, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(776, 'P0004', 1, 'ALARMA DE EMERGENCIA CON PALANCA DE JALON ', NULL, NULL, NULL, 12, NULL, NULL, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(777, 'P0005', 1, 'ALARMA DE EMERGENCIA CON SIRENA ESTROBO Y BOCINA', NULL, 150, NULL, 33, NULL, NULL, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(778, 'P0006', 1, 'ARENERO VERTICAL ROJO 100 LTS CON PATAS Y PALA ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(779, 'P0007', 1, 'ARENERO VERTICAL ROJO/AMARILLO 100 LTS CON LLANTAS', NULL, NULL, NULL, 7, NULL, NULL, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(780, 'P0008', 1, 'ARNES', 'Descripcion', NULL, NULL, 13, NULL, NULL, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(781, 'P0009', 1, 'BANDERIN PARA TRACTO-CAMION (22x50)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(782, 'P0010', 1, 'BANDEROLA NARANJA CON REFLEJANTE ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(783, 'P0011', 1, 'BARBIQUEJO CON MENTON ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(784, 'P0012', 1, 'BARBIQUEJO SIN MENTON ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(785, 'P0013', 1, 'BARRA ANTIPANICO HORIZONTAL DE 36\"', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(786, 'P0014', 1, 'BARRA ANTIPANICO HORIZONTAL DE 48\"', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(787, 'P0015', 1, 'BASTON LUMINOSO PARA TRAFICO (RECARGABLE)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(788, 'P0016', 1, 'BATA DE LABORATORIO', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(789, 'P0017', 1, 'BATERIA PARA DETECTOR DE HUMO ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(790, 'P0018', 1, 'BOLLA METALICA DE 20 x 20', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(791, 'P0019', 1, 'BOTA (107PN)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(792, 'P0020', 1, 'BOTA BLANCA PLASTICO (ILB)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(793, 'P0021', 1, 'BOTA BLANCA PLASTICO S/CASQUILLO PLANT ACERO (P/SA', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(794, 'P0022', 1, 'BOTA BORCEGUI CASCO ACERO (101ANH)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(795, 'P0023', 1, 'BOTA BORCEGUIE (109PLUS)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(796, 'P0024', 1, 'BOTA CAF? (777C)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(797, 'P0025', 1, 'BOTA CAF? DAMA (767PLUS) ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(798, 'P0026', 1, 'BOTA CHOCLO NEGRO CASCO  (8765PN)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(799, 'P0027', 1, 'BOTA DUCATI (782ASSEN)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(800, 'P0028', 1, 'BOTA NEGRA PLASTICO C/CASQUILLO PLANT ACERO (P/SAL', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(801, 'P0029', 1, 'BOTA PARA BOMBERO ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(802, 'P0030', 1, 'BOTA POLIAMIDA (107PLU-S) ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(803, 'P0031', 1, 'BOTA TACTICA NEGRA (610PLUS) ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(804, 'P0032', 1, 'BOTA TENIS NEGRO/ROSA DMA (120DAMA) ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(805, 'P0033', 1, 'BOTA TENIS NEGRO/VERDE SUELA POLIAMIDA (120HV)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(806, 'P0034', 1, 'BOTA WATER NEGRA PLASTICO (WPL)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(807, 'P0035', 1, 'BOTIQUIN INDUSTRIAL COMPLETO ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(808, 'P0036', 1, 'BOTIQUIN INDUSTRIAL VACIO (44x33x21)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(809, 'P0037', 1, 'BOTIQUIN MEDIANO COMPLETO', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(810, 'P0038', 1, 'BOTIQUIN MEDIANO VACIO (28x21x11)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL);
INSERT INTO `productos` (`Id_Producto`, `Codigo_prod`, `Tipo`, `Nombre_prod`, `Caracteristicas`, `Precio`, `Descuento`, `Cantidad_prod`, `Unidad_medida`, `Stock_minimo`, `Activo`, `Ubicacion`, `Cliente`, `Vendedor`, `CodigoQR`, `UCrea`, `FCrea`, `UAct`, `FAct`) VALUES
(811, 'P0039', 1, 'BOTIQUIN MINI (20x20x8)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(812, 'P0040', 1, 'BOTIQUIN MINI COMPLETO', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(813, 'P0041', 1, 'BRAZALETE PARA BRIGADA BORDADO C/REFLEJANTE ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(814, 'P0042', 1, 'BRAZALETE PARA BRIGADA SIN LEYENDA C/REFLEJANTE', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(815, 'P0043', 1, 'BROCHE O  CLIP P/GABINETE ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(816, 'P0044', 1, 'CADENA DE PLASTICO AMARILLA (50 MTS)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(817, 'P0045', 1, 'CAMILLA RIGIDA DE MADERA ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(818, 'P0046', 1, 'CAMILLA RIGIDA DE MADERA (con inmobilizador cranea', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(819, 'P0047', 1, 'CAMILLA RIGIDA DE PLASTICO', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(820, 'P0048', 1, 'CAMILLA RIGIDA DE PLASTICO (con inmobilizador cran', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(821, 'P0049', 1, 'CAMISA DE MEZCLILLA CON REFLEJANTE', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(822, 'P0050', 1, 'CAPACITACION BUSQUEDA Y RESCATE ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(823, 'P0051', 1, 'CAPACITACION DE INCENDIO EN CAMPO (PRECIO POR PERS', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(824, 'P0052', 1, 'CAPACITACION EVACUACION', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(825, 'P0053', 1, 'CAPACITACION PRIMEROS AUXILIOS (PRECIO GRUPO DE 20', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(826, 'P0054', 1, 'CAPACITACION USO Y MANEJO DE EXTINTORES', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(827, 'P0055', 1, 'CAPUCHA DE MEZCLILLA ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(828, 'P0056', 1, 'CASCO DE PLASTICO', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(829, 'P0057', 1, 'CASCO PARA BOMBERO ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(830, 'P0058', 1, 'CHALECO ALTA VISIBILIDAD CON REFLEJANTE ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(831, 'P0059', 1, 'CHALECO BRIGADISTA BASICO SIN BOLSAS', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(832, 'P0060', 1, 'CHALECO BRIGADISTA ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(833, 'P0061', 1, 'CHALECO DE MALLA C/REFLEJANTE VARIOS COLORES', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(834, 'P0062', 1, 'CHAPA C/LLAVE', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(835, 'P0063', 1, 'CHAQUETON PARA BOMBERO', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(836, 'P0064', 1, 'CHIFLON DE TRES PASOS 1.5\" IPT 80 GPM BRONCE ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(837, 'P0065', 1, 'CHIFLON DE TRES PASOS 1.5\" IPT 80 GPM POLICARBONAT', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(838, 'P0066', 1, 'CHIFLON DE TRES PASOS 1.5\" NST 80 GPM BRONCE', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(839, 'P0067', 1, 'CHIFLON DE TRES PASOS 1.5\" NST 80 GPM POLICARBONAT', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(840, 'P0068', 1, 'CHIFLON DE TRES PASOS 2.5\" IPT 120 GPM ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(841, 'P0069', 1, 'CHIFLON PARA MANGUERA DE EXTINTOR ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(842, 'P0070', 1, 'CINTA ANTIDERRAPANTE DE 1\" x 18mts\" ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(843, 'P0071', 1, 'CINTA ANTIDERRAPANTE DE 2\" x 18mts\" ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(844, 'P0072', 1, 'CINTA BARRICADA \"PELIGRO\" (305 mts) 4\"', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(845, 'P0073', 1, 'CINTA BARRICADA \"PRECAUCION\" (305 mts) 4\"', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(846, 'P0074', 1, 'CINTA BARRICADA \"PROHIBIDO EL PASO\" (305 mts) 4\"', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(847, 'P0075', 1, 'CINTA DE MARCAJE  COLOR 2\" (33mts)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(848, 'P0076', 1, 'CINTA DE MARCAJE  COLOR 4\" (33mts)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(849, 'P0077', 1, 'CINTA DE MARCAJE AMARILLO/ NEGRO 2\" (33mts)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(850, 'P0078', 1, 'CINTA DE MARCAJE AMARILLO/ NEGRO 4\" (33mts) ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(851, 'P0079', 1, 'CODO PARA EXT CO2 2.5 MARCA BADGER', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(852, 'P0080', 1, 'COFIA DE MALLA PARA CABELLO C/100 PIEZAS ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(853, 'P0081', 1, 'COFIA DESECHABLE C/100', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(854, 'P0082', 1, 'COLA DE COCHINO ACERO AL CARBON 1/4 ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(855, 'P0083', 1, 'COLA DE RATA BLANCO ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(856, 'P0084', 1, 'COLLARIN CERVICAL (BLANDO)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(857, 'P0085', 1, 'COLLARIN CERVICAL (RIGIDO)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(858, 'P0086', 1, 'CONO DE TRAFICO CON REFLEJANTE 45CM ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(859, 'P0087', 1, 'CONO DE TRAFICO CON REFLEJANTE 75 CM ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(860, 'P0088', 1, 'CONO DE TRAFICO CON REFLEJANTE 95 CM ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(861, 'P0089', 1, 'CONO DE TRAFICO MINI DE COLORES (naranja, blanco, ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(862, 'P0090', 1, 'CONO DE VIENTO 10\" DE DIAMETRO (MANGA) ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(863, 'P0091', 1, 'CONO DE VIENTO 18\" DE DIAMETRO\" (MANGA) ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(864, 'P0092', 1, 'CORNETA PARA EXTINTOR Co2 5 LBS ', '', 0, 0, 5, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(865, 'P0093', 1, 'CORNETA PARA EXTINTOR PQS', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(866, 'P0094', 1, 'CUBRE BOCAS (PIEZA)', '', 0, 0, 201, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(867, 'P0095', 1, 'CUBRE BOCAS C/150 PZAS', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(868, 'P0096', 1, 'CUBRE BOCAS C/200 PZAS', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(869, 'P0097', 1, 'CUBRE BOCAS C/50 PZAS', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(870, 'P0098', 1, 'CUBRE CASCO CON NUQUERA ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(871, 'P0099', 1, 'DETECTOR DE GAS ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(872, 'P0100', 1, 'DETECTOR DE GAS MANUAL', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(873, 'P0101', 1, 'DETECTOR HUMO', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(874, 'P0102', 1, 'DETECTOR HUMO CHINO S/PILA', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(875, 'P0103', 1, 'EMPAQUE O ASIENTO PARA VALVULA GLOBO 2\" ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(876, 'P0104', 1, 'EMPAQUE PARA HIDRANTE', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(877, 'P0105', 1, 'ESCAFANDRA PARA BOMBERO (MONJA) ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(878, 'P0106', 1, 'EXTINTOR NUEVO AFFF 6.0 LTS ACERO INOXIDABLE', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(879, 'P0107', 1, 'EXTINTOR NUEVO AFFF 9.4 LTS ACERO AL CARBON', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(880, 'P0108', 1, 'EXTINTOR NUEVO CO2  5 LIBRAS (2.3 KG) ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(881, 'P0109', 1, 'EXTINTOR NUEVO CO2 10 LIBRAS (4.5 KG) ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(882, 'P0110', 1, 'EXTINTOR NUEVO CO2 15 LIBRAS (6.5 KG) ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(883, 'P0111', 1, 'EXTINTOR NUEVO CO2 20 LIBRAS (9.0 KG) ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(884, 'P0112', 1, 'EXTINTOR NUEVO GAS HALOTRON 2.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(885, 'P0113', 1, 'EXTINTOR NUEVO GAS HALOTRON 4.5 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(886, 'P0114', 1, 'EXTINTOR NUEVO GAS HALOTRON 6.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(887, 'P0115', 1, 'EXTINTOR NUEVO H2O 9.04 LTS ACERO AL CARBON', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(888, 'P0116', 1, 'EXTINTOR NUEVO HFC 236 4.5 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(889, 'P0117', 1, 'EXTINTOR NUEVO HFC 236 6.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(890, 'P0118', 1, 'EXTINTOR NUEVO MICRO BLAZE 6.0 LTS', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(891, 'P0119', 1, 'EXTINTOR NUEVO MICRO BLAZE 9.4 LTS', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(892, 'P0120', 1, 'EXTINTOR NUEVO PQS  1.0 KG', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(893, 'P0121', 1, 'EXTINTOR NUEVO PQS  2.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(894, 'P0122', 1, 'EXTINTOR NUEVO PQS  4.5 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(895, 'P0123', 1, 'EXTINTOR NUEVO PQS  6.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(896, 'P0124', 1, 'EXTINTOR NUEVO PQS  9.0 KG', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(897, 'P0125', 1, 'EXTINTOR NUEVO PQS 12.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(898, 'P0126', 1, 'EXTINTOR NUEVO TIPO K 6.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(899, 'P0127', 1, 'EXTINTOR NUEVO TIPO K 9.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(900, 'P0128', 1, 'EXTINTOR SEMINUEVO PQS 4.5 KG', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(901, 'P0129', 1, 'EXTINTOR SEMINUEVO PQS 6.0 KG', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(902, 'P0130', 1, 'EXTINTOR SEMINUEVO PQS 9.0 KG', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(903, 'P0131', 1, 'FAJA CON TERCER CINTURON ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(904, 'P0132', 1, 'FAJA TIPO PESISTA SIN TIRANTES ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(905, 'P0133', 1, 'FUNDA PARA ARENERO 100 LTS ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(906, 'P0134', 1, 'FUNDA PARA EXTINTOR CO2  5 LIBRAS', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(907, 'P0135', 1, 'FUNDA PARA EXTINTOR CO2 10 LIBRAS', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(908, 'P0136', 1, 'FUNDA PARA EXTINTOR CO2 15 LIBRAS', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(909, 'P0137', 1, 'FUNDA PARA EXTINTOR CO2 20 LIBRAS', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(910, 'P0138', 1, 'FUNDA PARA EXTINTOR PQS  1.0 Y 2.0 KG', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(911, 'P0139', 1, 'FUNDA PARA EXTINTOR PQS  4.5 Y 6.0 KG', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(912, 'P0140', 1, 'FUNDA PARA EXTINTOR PQS  9.0 KG', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(913, 'P0141', 1, 'FUNDA PARA EXTINTOR PQS 12.0 KG', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(914, 'P0142', 1, 'FUNDA PARA HIDRANTE ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(915, 'P0143', 1, 'FUNDA PARA UNIDAD MOVIL 35.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(916, 'P0144', 1, 'FUNDA PARA UNIDAD MOVIL 50.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(917, 'P0145', 1, 'FUNDA PARA UNIDAD MOVIL 70.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(918, 'P0146', 1, 'GABINETE PARA 1 EQUIPO DE BOMBERO ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(919, 'P0147', 1, 'GABINETE PARA 2 EQUIPO DE BOMBERO ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(920, 'P0148', 1, 'GABINETE PARA 4 EQUIPO DE BOMBERO ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(921, 'P0149', 1, 'GABINETE PARA 6 EQUIPO DE BOMBERO ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(922, 'P0150', 1, 'GABINETE PARA CAMILLA', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(923, 'P0151', 1, 'GABINETE PARA CAMILLA (AMPLIA)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(924, 'P0152', 1, 'GABINETE PARA EXTINTOR PQS 4.5 KG', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(925, 'P0153', 1, 'GABINETE PARA EXTINTOR PQS 6.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(926, 'P0154', 1, 'GABINETE PARA EXTINTOR PQS 9.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(927, 'P0155', 1, 'GABINETE PARA MANGUERA IND DE 30 MTS Y EXTINTOR  P', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(928, 'P0156', 1, 'GABINETE PARA MANGUERA IND. DE  2\" x 30 MTS SOBREP', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(929, 'P0157', 1, 'GABINETE PARA MANGUERA IND. DE 1.5\" x 15 MTS EMPOT', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(930, 'P0158', 1, 'GABINETE PARA MANGUERA IND. DE 1.5\" x 15 MTS SOBRE', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(931, 'P0159', 1, 'GABINETE PARA MANGUERA IND. DE 1.5\" x 30 MTS EMPOT', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(932, 'P0160', 1, 'GABINETE PARA MANGUERA IND. DE 1.5\" x 30 MTS SOBRE', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(933, 'P0161', 1, 'GAFAS PARA SOLDADOR', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(934, 'P0162', 1, 'GOGLE', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(935, 'P0163', 1, 'GUANTE ANTICORTE (GLANTICUT9)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(936, 'P0164', 1, 'GUANTE DE CARNAZA CHICO', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(937, 'P0165', 1, 'GUANTE DE CARNAZA LARGO ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(938, 'P0166', 1, 'GUANTE DE CARNAZA PARA SOLDADOR', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(939, 'P0167', 1, 'GUANTE DE PIEL GUANTES', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(940, 'P0168', 1, 'GUANTE JAPONES CON PUNTOS DE PVC ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(941, 'P0169', 1, 'GUANTE LATEX DESECHABLE CAJA C/100', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(942, 'P0170', 1, 'GUANTE NEGRO NYLON ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(943, 'P0171', 1, 'GUANTE NITRILO AZUL GUANTES (GLNA9)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(944, 'P0172', 1, 'GUANTE TIPO ELECTRICISTA C/PU?O DE CARNAZA GUANTES', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(945, 'P0173', 1, 'GUANTES PARA BOMBERO ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(946, 'P0174', 1, 'HACHA PICO DE 70 CM ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(947, 'P0175', 1, 'IMPERMEABLE 2 PIEZAS ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(948, 'P0176', 1, 'IMPERMEABLE GABARDINA ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(949, 'P0177', 1, 'IMPERMEABLE MANGA UNITALLA/PONCHO ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(950, 'P0178', 1, 'INDICADOR PISO MOJADO TIPO TIJERA', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(951, 'P0179', 1, 'INMOVILIZADOR CRANEAL ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(952, 'P0180', 1, 'KIT DE MEDICAMENTO ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(953, 'P0181', 1, 'LAMPARA DE EMERGENCIA 2 FOCOS LED ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(954, 'P0182', 1, 'LAMPARA DE EMERGENCIA DE 60 LED', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(955, 'P0183', 1, 'LAMPARA DE MANO', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(956, 'P0184', 1, 'LAMPARA SOLAR', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(957, 'P0185', 1, 'LAVA OJOS C/REGADERA ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(958, 'P0186', 1, 'LENTE ANTIEMPA?ANTE (TORNADO)   ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(959, 'P0187', 1, 'LENTE VICA VISION 4000', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(960, 'P0188', 1, 'LENTES POLICARBONATO AMBAR', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(961, 'P0189', 1, 'LENTES POLICARBONATO NEGRO', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(962, 'P0190', 1, 'LENTES POLICARBONATO TRANSPARENTES ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(963, 'P0191', 1, 'LINEA DE VIDA CON AMORTIGUADOR', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(964, 'P0192', 1, 'LINEA DE VIDA SENCILLA', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(965, 'P0193', 1, 'LINTERNA MANOS LIBRES ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(966, 'P0194', 1, 'LLAVE UNIVERSAL PARA AJUSTAR COPLES', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(967, 'P0195', 1, 'MALLA DELIMITANTE (NARANJA 1.20x30MTS)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(968, 'P0196', 1, 'MANGA DESECHABLE C/50 PARES', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(969, 'P0197', 1, 'MANGUERA CON CORNETA PARA CO2 10/20 LIBRAS ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(970, 'P0198', 1, 'MANGUERA INCENDIO 1.5\" X 15 mts IPT doble capa (br', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(971, 'P0199', 1, 'MANGUERA INCENDIO 1.5\" X 15 mts NST doble capa (br', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(972, 'P0200', 1, 'MANGUERA INCENDIO 1.5\" X 30 mts IPT doble capa (br', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(973, 'P0201', 1, 'MANGUERA INDUSTRIAL 1.5\" X 15 mts IPT (bronce)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(974, 'P0202', 1, 'MANGUERA INDUSTRIAL 1.5\" X 15 mts NST (bronce)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(975, 'P0203', 1, 'MANGUERA INDUSTRIAL 1.5\" X 30 mts IPT (bronce)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(976, 'P0204', 1, 'MANGUERA INDUSTRIAL 1.5\" X 30 mts NST (bronce)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(977, 'P0205', 1, 'MANGUERA INDUSTRIAL 2\" X 15 mts solo cuerda IPT (b', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(978, 'P0206', 1, 'MANGUERA INDUSTRIAL 2\" X 30 mts solo cuerda IPT (b', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(979, 'P0207', 1, 'MANGUERA INDUSTRIAL 2.5\" X 30 mts IPT (bronce)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(980, 'P0208', 1, 'MANGUERA PARA EXTINTOR ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(981, 'P0209', 1, 'MANGUERA PARA UNIDAD MOVIL                   ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(982, 'P0210', 1, 'MANGUERA PARA UNIDAD MOVIL AGUA/ESPUMA CON PISTOLA', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(983, 'P0211', 1, 'MANIJA INFERIOR PARA EXTINTOR DE 1.0KG Y 2.0kg ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(984, 'P0212', 1, 'MANIJA O JALADERA P/GABINETE', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(985, 'P0213', 1, 'MANIJA SUPERIOR PARA EXTINTOR DE 1.0KG y 2.0KG', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(986, 'P0214', 1, 'MANIQUIES PARA PRACTICA RCP ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(987, 'P0215', 1, 'MANOMETRO PARA EXTINTOR ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(988, 'P0216', 1, 'MANTA CONTRA INCENDIO 100% FIBRA DE VIDRIO (1.00x1', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(989, 'P0217', 1, 'MANTA CONTRA INCENDIO 100% FIBRA DE VIDRIO (1.20x1', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(990, 'P0218', 1, 'MANTA CONTRA INCENDIO 100% LANA (1.58x2.12)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(991, 'P0219', 2, 'MANTENIMIENTO A EXTINTOR AFFF 6.0 LT', '', 150, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(992, 'P0220', 2, 'MANTENIMIENTO A EXTINTOR AFFF 9.0 LT', NULL, NULL, NULL, 1, NULL, NULL, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(993, 'P0221', 2, 'MANTENIMIENTO A EXTINTOR Co2 10 LIBRAS (4.5 KG ) ', NULL, NULL, NULL, 1, NULL, NULL, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(994, 'P0222', 2, 'MANTENIMIENTO A EXTINTOR Co2 15 LIBRAS (6.5 KG ) ', NULL, NULL, NULL, 1, NULL, NULL, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(995, 'P0223', 2, 'MANTENIMIENTO A EXTINTOR Co2 20 LIBRAS (9.0 KG ) ', NULL, NULL, NULL, 1, NULL, NULL, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(996, 'P0224', 2, 'MANTENIMIENTO A EXTINTOR Co2 5 LIBRAS (2.3 KG ) ', NULL, NULL, NULL, 1, NULL, NULL, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(997, 'P0225', 2, 'MANTENIMIENTO A EXTINTOR GAS HALOTRON 1.0 KG ', NULL, NULL, NULL, 1, NULL, NULL, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(998, 'P0226', 2, 'MANTENIMIENTO A EXTINTOR GAS HALOTRON 2.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(999, 'P0227', 2, 'MANTENIMIENTO A EXTINTOR GAS HALOTRON 4.5 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1000, 'P0228', 2, 'MANTENIMIENTO A EXTINTOR GAS HALOTRON 6.0KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1001, 'P0229', 2, 'MANTENIMIENTO A EXTINTOR H2O 4.0 LT ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1002, 'P0230', 2, 'MANTENIMIENTO A EXTINTOR H2O 6.0 LT ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1003, 'P0231', 2, 'MANTENIMIENTO A EXTINTOR H2O 9.46 LT ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1004, 'P0232', 2, 'MANTENIMIENTO A EXTINTOR MB DE 6.0 LT ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1005, 'P0233', 2, 'MANTENIMIENTO A EXTINTOR MB DE 9.0 LT ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1006, 'P0234', 2, 'MANTENIMIENTO A EXTINTOR PQS 1.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1007, 'P0235', 2, 'MANTENIMIENTO A EXTINTOR PQS 12.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1008, 'P0236', 2, 'MANTENIMIENTO A EXTINTOR PQS 2.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1009, 'P0237', 2, 'MANTENIMIENTO A EXTINTOR PQS 4.5 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1010, 'P0238', 2, 'MANTENIMIENTO A EXTINTOR PQS 6.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1011, 'P0239', 2, 'MANTENIMIENTO A EXTINTOR PQS 9.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1012, 'P0240', 2, 'MANTENIMIENTO A EXTINTOR Tipo K 6.0 LT ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1013, 'P0241', 2, 'MANTENIMIENTO A EXTINTOR Tipo K 9.0 LT ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1014, 'P0242', 2, 'MANTENIMIENTO A UNIDAD MOVIL PQS 35.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1015, 'P0243', 2, 'MANTENIMIENTO A UNIDAD MOVIL PQS 50.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1016, 'P0244', 2, 'MANTENIMIENTO A UNIDAD MOVIL PQS 70.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1017, 'P0245', 1, 'MARTILLO DE GOMA', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1018, 'P0246', 1, 'MASCARILLA PARA PARTICULAS SOLIDAS CON VALVULA ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1019, 'P0247', 1, 'MASCARILLA PARA PARTICULAS SOLIDAS SIN VALVULA ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1020, 'P0248', 1, 'MASCARILLA RESPIRADOR MEDIA CARA 1 CARTUCHO ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1021, 'P0249', 1, 'MASCARILLA RESPIRADOR MEDIA CARA 2 CARTUCHOS ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1022, 'P0250', 1, 'MAZO TUBO ROJO', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1023, 'P0251', 1, 'MEGAFONO DE 25 WATTS CON GRABADORA DE VOZ Y BATERI', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1024, 'P0252', 1, 'MEGAFONO DE HOMBRO CON SIRENA Y MICROFONO COLGANTE', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1025, 'P0253', 1, 'MOCHILA BOTIQUIN MINIMEDIC EQUIPADA', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1026, 'P0254', 1, 'MOCHILA BOTIQUIN MINIMEDIC SIN EQUIPAR ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1027, 'P0255', 1, 'MUSGO PARA ARENERO (COSTAL 10 kg)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1028, 'P0256', 1, 'NUQUERA DE MALLA CON REFLEJANTE ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1029, 'P0257', 1, 'OREJERA PARA RUIDO TIPO DIADEMA', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1030, 'P0258', 1, 'OVEROL AZUL CON REFLEJANTE', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1031, 'P0259', 1, 'OVEROL BLANCO DESECHABLE', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1032, 'P0260', 1, 'OVEROL DESECHABLE PARA QUIMICOS ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1033, 'P0261', 1, 'PALA PARA ESCOMBRO ANTI CHISPA ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1034, 'P0262', 1, 'PALA PARA ARENERO ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1035, 'P0263', 1, 'PANTALON DE BOMBERO', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1036, 'P0264', 1, 'PANTALON DE MEZCLILLA C/REFLEJANTE', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1037, 'P0265', 1, 'PAQUETE 1 INCLUYE (EXTINTOR PQS 4.5 KG, BOTIQUIN C', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1038, 'P0266', 1, 'PAQUETE 2 INCLUYE (EXTINTOR PQS 6.0 KG, BOTIQUIN C', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1039, 'P0267', 1, 'PILA PARA DETECTOR DE HUMO ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1040, 'P0268', 1, 'PLAYERA POLO C/REFLEJANTE', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1041, 'P0269', 1, 'PORTA EXTINTOR CILINDRICO PARA CO2 10 Lbs ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1042, 'P0270', 1, 'PORTA EXTINTOR CILINDRICO PARA CO2  5 Lbs ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1043, 'P0271', 1, 'PORTA EXTINTOR CILINDRICO PARA PQS 4.5 Y 6.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1044, 'P0272', 1, 'PORTA EXTINTOR CIRCULAR CO2  5 LIBRAS  (ACERO INOX', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1045, 'P0273', 1, 'PORTA EXTINTOR CIRCULAR CO2 10 LIBRAS  (ACERO INOX', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1046, 'P0274', 1, 'PORTA EXTINTOR CIRCULAR CO2 15 Y 20 LIBRAS  (ACERO', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1047, 'P0275', 1, 'PORTA EXTINTOR CIRCULAR PQS 4.5 KG  (ACERO INOXIDA', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1048, 'P0276', 1, 'PORTA EXTINTOR CIRCULAR PQS 4.5 KG (COLORES)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1049, 'P0277', 1, 'PORTA EXTINTOR CIRCULAR PQS 6.0 KG  (ACERO INOXIDA', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1050, 'P0278', 1, 'PORTA EXTINTOR CIRCULAR PQS 6.0 KG (COLORES)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1051, 'P0279', 1, 'PORTA EXTINTOR CIRCULAR PQS 9.0 KG  (ACERO INOXIDA', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1052, 'P0280', 1, 'PORTA EXTINTOR CIRCULAR PQS 9.0 KG (COLORES)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1053, 'P0281', 1, 'PORTA EXTINTOR CUADRADO CO2 5 LIBRAS  (ACERO INOXI', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1054, 'P0282', 1, 'PORTA EXTINTOR CUADRADO PQS 4.5 A 9.0 KG (ACERO IN', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1055, 'P0283', 1, 'PORTA EXTINTOR CUADRADO PQS 4.5 Y 6.0KG (COLORES)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1056, 'P0284', 1, 'PORTA EXTINTOR MEDIA LUNA  CO2 10 LIBRAS (ACERO IN', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1057, 'P0285', 1, 'PORTA EXTINTOR MEDIA LUNA  PQS 4.5 Y 6.0 KG (ACERO', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1058, 'P0286', 1, 'PORTA EXTINTOR MEDIA LUNA  PQS 9.0 KG (ACERO INOXI', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1059, 'P0287', 1, 'POSTE NARANJA CON BASE NEGRA 1PIEZA', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1060, 'P0288', 1, 'PRUEBA HIDROSTATICA A EXTINTOR Co2 ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1061, 'P0289', 1, 'PRUEBA HIDROSTATICA A HIDRANTE', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1062, 'P0290', 1, 'PRUEBA HIDROSTATICA A UNIDAD MOVIL ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1063, 'P0291', 1, 'PRUEBA HIDROSTATICA EXTINTOR PQS', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1064, 'P0292', 1, 'RADIO 2 VIAS MOTOROLA T400MC 46 KM', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1065, 'P0293', 2, 'RECARGA A EXTINTOR DE AFFF 6.0 KG ', '', 300, 0, 4, '', 0, NULL, 'INVENTARIO', 4, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1066, 'P0294', 2, 'RECARGA A EXTINTOR DE AFFF 9.4 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1067, 'P0295', 2, 'RECARGA A EXTINTOR DE CO2  5 LIBRAS (2.3 KG)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1068, 'P0296', 2, 'RECARGA A EXTINTOR DE CO2 10 LIBRAS (4.5 KG) ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1069, 'P0297', 2, 'RECARGA A EXTINTOR DE CO2 15 LIBRAS ( 6.8 KG) ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1070, 'P0298', 2, 'RECARGA A EXTINTOR DE CO2 20 LIBRAS ( 9.0 KG) ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1071, 'P0299', 2, 'RECARGA A EXTINTOR H2O 4.0 LTS', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1072, 'P0300', 2, 'RECARGA A EXTINTOR H2O 6.0 LTS', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1073, 'P0301', 2, 'RECARGA A EXTINTOR HALOTRON 1.0 KG', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1074, 'P0302', 2, 'RECARGA A EXTINTOR HALOTRON 2.0 KG', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1075, 'P0303', 2, 'RECARGA A EXTINTOR HALOTRON 4.5 KG', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1076, 'P0304', 2, 'RECARGA A EXTINTOR HALOTRON 6.0 KG', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1077, 'P0305', 2, 'RECARGA A EXTINTOR HCF 236 1.0 KG', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1078, 'P0306', 2, 'RECARGA A EXTINTOR K 6.0 LT ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1079, 'P0307', 2, 'RECARGA A EXTINTOR K 9.0 LT ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1080, 'P0308', 2, 'RECARGA A EXTINTOR MB DE 6.0 LTS', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1081, 'P0309', 2, 'RECARGA A EXTINTOR MB DE 9.4 LT ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1082, 'P0310', 2, 'RECARGA A EXTINTOR PQS 1.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1083, 'P0311', 2, 'RECARGA A EXTINTOR PQS 12.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1084, 'P0312', 2, 'RECARGA A EXTINTOR PQS 2.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1085, 'P0313', 2, 'RECARGA A EXTINTOR PQS 4.5 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1086, 'P0314', 2, 'RECARGA A EXTINTOR PQS 6.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1087, 'P0315', 2, 'RECARGA A EXTINTOR PQS 9.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1088, 'P0316', 2, 'RECARGA A UNIDAD MOVIL PQS 34.0KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1089, 'P0317', 2, 'RECARGA A UNIDAD MOVIL PQS 50.0.KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1090, 'P0318', 1, 'RECARGA A UNIDAD MOVIL PQS 70.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1091, 'P0319', 1, 'RESUCITADOR MANUAL (desechable)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1092, 'P0320', 1, 'RESUCITADOR MANUAL (reutilizable)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1093, 'P0321', 1, 'RETARDANTE PARA MADERAS TRATADAS   4 LTS', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1094, 'P0322', 1, 'RETARDANTE PARA MADERAS TRATADAS 19 LTS', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1095, 'P0323', 1, 'RETARDANTE PARA MADERAS VIRGENES    4 LTS', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1096, 'P0324', 1, 'RETARDANTE PARA MADERAS VIRGENES  20 LTS', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1097, 'P0325', 1, 'RETARDANTE PARA PALAPAS  4 LTS', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1098, 'P0326', 1, 'RETARDANTE PARA PALAPAS 19 LTS', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1099, 'P0327', 1, 'RETARDANTE PARA TEXTILES, TELAS Y ALFOMBRAS PORRON', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1100, 'P0328', 1, 'RETARDANTE PARA TEXTILES, TELAS Y ALFOMBRAS PORRON', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1101, 'P0329', 1, 'RETARDANTE SELLADOR PARA PALAPAS 19 LTS', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1102, 'P0330', 1, 'ROCIADOR 68', NULL, NULL, NULL, 1, NULL, NULL, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1103, 'P0331', 1, 'SEGURO PARA EXTINTOR', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1104, 'P0332', 1, 'SEÑAL DE ALTO TIPO PALETA PARA POSTE VIAL ', NULL, NULL, NULL, 1, NULL, NULL, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1105, 'P0333', 1, 'SILBATO CON CORDON NEGRO', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1106, 'P0334', 1, 'SILBATO SIN CORDON COLORES', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1107, 'P0335', 1, 'SOPORTE ABRAZADERA EXT. 1.0 KG', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1108, 'P0336', 1, 'SOPORTE ABRAZADERA EXT. 2.0 KG', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1109, 'P0337', 1, 'SOPORTE BASE TUBULAR PARA EXTINTOR ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1110, 'P0338', 1, 'SOPORTE DE DESPLIEGUE RAPIDO P/MANGUERA INDUSTRIAL', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1111, 'P0339', 1, 'SOPORTE O CINCHO PARA EXTINTOR CO2 EN ACERO INOXID', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1112, 'P0340', 1, 'SOPORTE P/EXTINTOR AUTOTANQUE  9.0kg ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1113, 'P0341', 1, 'SOPORTE P/EXTINTOR AUTOTANQUE 4.5 y 6.kg ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1114, 'P0342', 1, 'SOPORTE P/EXTINTOR DOBLE FLEJE 4.5 KG', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1115, 'P0343', 1, 'SOPORTE P/EXTINTOR DOBLE FLEJE 6.0 KG', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1116, 'P0344', 1, 'SOPORTE P/EXTINTOR DOBLE FLEJE 9.0 KG', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1117, 'P0345', 1, 'SOPORTE P/EXTINTOR TIPO L ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1118, 'P0346', 1, 'SOPORTE P/EXTINTOR TIPO TOTAL', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1119, 'P0347', 1, 'SUJETADOR PARA CAMILLA (ARA?A)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1120, 'P0348', 1, 'SUSPENSION PARA CASCO', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1121, 'P0349', 1, 'TAPETE ANTIFATIGA 90x90 TAPETE', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1122, 'P0350', 1, 'TAPON AUDITIVO DESECHABLE', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1123, 'P0351', 1, 'TAPON TOMA SIAMESA 2.5\" NST MACHO CROMADO CON CADE', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1124, 'P0352', 1, 'TAPON TOMA SIAMESA 2.5\" NST MACHO PLASTICO CON CAD', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1125, 'P0353', 1, 'TAPON TOMA SIAMESA 2.5\" NST MACHO PLASTICO CON CAD', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1126, 'P0354', 1, 'TIRANTES PARA BOMBERO ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1127, 'P0355', 1, 'TOMA SIAMESA GRANALLADA Y CROMADA', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1128, 'P0356', 1, 'TOPE DE 1.78 MTS (1 pza) ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1129, 'P0357', 1, 'TOPE FRENO P/LLANTA PESADA (PAR) CALZA', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1130, 'P0358', 1, 'TOPE FRENO P/LLANTA PESADA (PIEZA) CALZA', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1131, 'P0359', 1, 'TOPES DE 50 CM C/TORNILLO (PAR) ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1132, 'P0360', 1, 'TRAFITAMBO VIAL C/EFLEJANTE', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1133, 'P0361', 1, 'TRAJE PARA COMPLETO PARA BOMBERO', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1134, 'P0362', 1, 'TUBO SIFON DE UNIDAD MOVIL ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1135, 'P0363', 1, 'TUBO SIFON EXT 1.0 A 2.0 Kg. ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL);
INSERT INTO `productos` (`Id_Producto`, `Codigo_prod`, `Tipo`, `Nombre_prod`, `Caracteristicas`, `Precio`, `Descuento`, `Cantidad_prod`, `Unidad_medida`, `Stock_minimo`, `Activo`, `Ubicacion`, `Cliente`, `Vendedor`, `CodigoQR`, `UCrea`, `FCrea`, `UAct`, `FAct`) VALUES
(1136, 'P0364', 1, 'UNIDAD MOVIL NUEVO AFFF 50.0 KG', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1137, 'P0365', 1, 'UNIDAD MOVIL NUEVO PQS DE 35.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1138, 'P0366', 1, 'UNIDAD MOVIL NUEVO PQS DE 50.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1139, 'P0367', 1, 'UNIDAD MOVIL NUEVO PQS DE 70.0 KG ', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1140, 'P0368', 1, 'VALVULA EXTINTOR 1.0 KG Y 2.0 KG completa', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1141, 'P0369', 1, 'VALVULA EXTINTOR 4.5 KG A 9.0 KG completa', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1142, 'P0370', 1, 'VALVULA GLOBO 2\" HEMBRA IPT A 1.5\" MACHO IPT', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1143, 'P0371', 1, 'VALVULA GLOBO 2\" HEMBRA IPT A 1.5\" MACHO NST', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1144, 'P0372', 1, 'VALVULA GLOBO 2\" HEMBRA IPT A 2\" MACHO NST', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1145, 'P0373', 1, 'VASTAGO EXTINTOR CO2 (BADGER)', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1146, 'P0374', 1, 'VASTAGO PARA EXTINTOR', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1147, 'P0375', 1, 'VIALETA AMARILLA', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1148, 'P0376', 1, 'VIALETA BLANCA', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL),
(1149, 'P0377', 1, 'VOLANTE ROJO PARA VALVULA GLOBO DE 1.5\" Y 2.0\"', '', 0, 0, 1, '', 0, NULL, 'INVENTARIO', NULL, NULL, NULL, 1, '2022-02-08 00:04:00', NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos_proveedores`
--

CREATE TABLE `productos_proveedores` (
  `Id_PP` bigint(20) UNSIGNED NOT NULL,
  `Id_Producto` bigint(20) UNSIGNED DEFAULT NULL,
  `Id_Proveedor` bigint(20) UNSIGNED DEFAULT NULL,
  `UCrea` bigint(20) UNSIGNED DEFAULT NULL,
  `FCrea` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `UAct` bigint(20) UNSIGNED DEFAULT NULL,
  `FAct` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos_tipos`
--

CREATE TABLE `productos_tipos` (
  `Id_Tipo` bigint(20) UNSIGNED NOT NULL,
  `Tipo` varchar(50) COLLATE utf8_spanish_ci DEFAULT NULL,
  `UCrea` bigint(20) UNSIGNED DEFAULT NULL,
  `FCrea` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `UAct` bigint(20) UNSIGNED DEFAULT NULL,
  `FAct` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `productos_tipos`
--

INSERT INTO `productos_tipos` (`Id_Tipo`, `Tipo`, `UCrea`, `FCrea`, `UAct`, `FAct`) VALUES
(1, 'PRODUCTO', 1, '2022-02-07 23:59:04', 1, '2022-02-08 00:00:07'),
(2, 'SERVICIO', 1, '2022-02-07 23:59:04', 1, '2022-02-08 00:00:10'),
(3, 'EMERGENTE', 1, '2022-02-07 23:59:04', 1, '2022-02-08 00:00:13');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proveedores`
--

CREATE TABLE `proveedores` (
  `Id_Proveedor` bigint(20) UNSIGNED NOT NULL,
  `Nombre` varchar(100) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Contacto` varchar(100) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Tel1` varchar(15) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Ext1` varchar(10) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Tel2` varchar(15) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Ext2` varchar(15) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Direccion` varchar(100) COLLATE utf8_spanish_ci DEFAULT NULL,
  `NumExt` varchar(30) COLLATE utf8_spanish_ci DEFAULT NULL,
  `CP` varchar(10) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Colonia` varchar(50) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Municipio` varchar(50) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Entidad` varchar(50) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Pais` varchar(50) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Horario` varchar(100) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Condiciones_pago` varchar(100) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Email` varchar(100) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Website` varchar(255) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Facebook` varchar(255) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Twitter` varchar(150) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Instagram` varchar(150) COLLATE utf8_spanish_ci DEFAULT NULL,
  `UCrea` bigint(20) UNSIGNED DEFAULT NULL,
  `FCrea` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `UAct` bigint(20) UNSIGNED DEFAULT NULL,
  `FAct` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `proveedores`
--

INSERT INTO `proveedores` (`Id_Proveedor`, `Nombre`, `Contacto`, `Tel1`, `Ext1`, `Tel2`, `Ext2`, `Direccion`, `NumExt`, `CP`, `Colonia`, `Municipio`, `Entidad`, `Pais`, `Horario`, `Condiciones_pago`, `Email`, `Website`, `Facebook`, `Twitter`, `Instagram`, `UCrea`, `FCrea`, `UAct`, `FAct`) VALUES
(1, 'ACRILICOS GARBA', 'GERARDO GARCIA', '333603-2233', '', '', '', 'BELISARIO DOMINGUEZ', '2587', '', 'LA ESPERANZA', '', '', '', '', 'contado/efectivo', 'acrilicos@gmail.com', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(2, 'ACTION FIRE', '', '333145-1299', '', '', '', 'AV. GOBERNADOR LUIS CURIEL', '2794', '', 'ZONA INDUSTRIAL', '', '', '', '', 'transferencia 30 dias', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(3, 'ADHECINTAS', '', '333585-9116', '', '', '', 'AV. CAMINO A STA. ANA TEPETITLAN', '134', '', 'SANTA ANA TEPETITLAN', '', '', '', '', 'contado/efectivo', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(4, 'ART SERIGRAF', '', '333825-9065', '', '', '', 'HOSPITAL', '1433B', '', 'SANTA TERESITA', '', '', '', '9 a 2 y 3 a 6  L-V', 'transferencia 30 dias', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(5, 'ARTURO BORDADOS', '', '331136-1489', '', '', '', 'MIGUEL GALINDO', '349', '', 'SAN BERNARDO', '', '', '', '9 A 6', 'transferencia', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(6, 'BASCULAS IRIDIO', '', '333343-6266', '', '', '', 'PROV. TABACHINES', '3207', '', 'LOMA BONITA EJIDAL', '', '', '', '', 'contado/efectivo', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(7, 'BIME', '', '331383-1105', '', '', '', 'LAZARO CARDENAS', '1800', '', 'DEL FRESNO', '', '', '', '9 A 6', 'transferencia 30 dias', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(8, 'DIKASA', '', '331542-4860', '', '', '', 'AV. ESCORIAL', '2073', '', 'LOMAS DE ZAPOPAN', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(9, 'DINAMICA', '', '333827-1397', '', '', '', 'PUERTO GUAYMAS', '897-A', '', 'MIRAMAR', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(10, 'EMPAQUES DENNISSE', '', '333633 3270', '', '', '', 'LOPEZ COTILLA', '662A', '', 'CENTRO', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(11, 'EMPAQUES SALMI', '', '333683-9407', '', '', '', 'REYNA DE LUXEMBURGO', '953', '', 'PRIVADA DE LA REYNA', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(12, 'EMPRESAS RANGEL', '', '333180-2250', '', '', '', 'AV. PROL. EL COLLI ', '1181', '', 'PARAISOS DEL COLLI', '', '', '', '8:30 a 2 y 3 a 6:30', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(13, 'EQ. VS INC. PEPES', '', '331524-2019', '', '', '', 'NUDO DE CEMPOALTEPEC', '1223', '', 'SAN VICENTE', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(14, 'ERETZ', '', '01 5526316930', '', '', '', '7', '232', '', 'PORVENIR', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(15, 'EXTINTORES TEPEYAC', '', '01 555 397 9393', '', '', '', 'MEXICO COOPERATIVO', '19', '', 'MEXICO NUEVO', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(16, 'FERRETERIA EL ARCA DE NOE', '', '333126-0897', '', '', '', 'VENUSTIANO CARRANZA', '697', '', 'CONSTITUCION', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(17, 'FERRETERIAS CALZADA', '', '83470187', '', '', '', 'AV. LAZARO CARDENAS', '799', '', 'ZONA INDUSTRIAL', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(18, 'GENERAL PAINT', '', '331816-3489', '', '', '', 'MILPA ', '42', '', 'FRANCISCO SARABIA', '', '', '', '9 a 6', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(19, 'GIMSA', '', '333632-9910', '', '', '', 'AV. COLON', '5507', '', 'NUEVA ESPAÑA', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(20, 'IMPRENTA VISION GRAFICA', '', '331581-7216', '', '', '', 'PASTOR ROUAIX', '355A', '', 'CONSTITUCION', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(21, 'INSTRUTEK', '', '333618-0998', '', '', '', 'FEDERACION', '685', '', 'SAN JUAN DE DIOS', '', '', '', '9 a 6 L-V', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(22, 'JOBS', '', '01 449 913 1306', '', '', '', 'MICHOACAN', '118', '', 'MEXICO', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(23, 'LICA', '', '333145-2353', '', '', '', 'AV. PERIFERICO PONIENTE', '10471', '', 'PARQUE IND EL COLLI', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(24, 'LICA', '', '333656-1656', '', '', '', 'AV. LAURELES', '118', '', '', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(25, 'MAF EXTINTORES', '', '01 555 828 9617', '', '', '', 'MIGUEL HIDALGO', '38', '', 'NICOLAS ROMERO', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(26, 'MAGOCAD', '', '', '', '', '', 'CALLE CAIRO', '1249', '', 'SAN EUGENIO', '', '', '', '8:30 a 6:30', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(27, 'MAPRE', '', '552594-3426', '', '', '', 'LAGO DE LOS SUEÑOS ', 'MZ.72', '', 'SELENE', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(28, 'MEDILAB', '', '333613 0987', '', '', '', 'FEDERALISMO  ', '5', '', 'CENTRO', '', '', '', '9 a 7', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(29, 'MTTO INDUSTRIAL', '', '333645-7139', '', '', '', 'FCO. C. MORALES', '1506', '', 'ECHEVERRIA', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(30, 'MUNDIMED', '', '333826-2599', '', '', '', 'FEDERALISMO NTE', '475', '', 'ARTESANOS', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(31, 'MYVAME', '', '333810-3324', '', '', '', 'MARCO POLO', '2867', '', '18 DE MARZO', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(32, 'PAPELERA TORO', '', '333853-8003', '', '', '', 'MARIANO DE LA BARCENA', '1283', '', 'LA NORMAL', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(33, 'PLASTIBOL', '', '333165-9064', '', '', '', 'VENUSTIANO CARRANZA', '222-A', '', 'CONSTITUCION', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(34, 'PRE-VN FIRE', '', '3331695428', '', '3331695435', '', 'CALZ. LAZARO CARDENAS', '2140', '', 'DEL FRESNO', '', '', '', '9:30 a 6', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(35, 'PROVEJAL', '', '333650-0035', '', '', '', 'CHICAGO', '1278', '', 'FERROCARRIL', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(36, 'RKH', '', '332215-2227', '', '', '', 'ADMINISTRADORES', '5294', '', 'JARDINES DE GUADALUPE', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(37, 'RYVEA', '', '333825-1427', '', '', '', 'GREGORIO DAVILA', '643', '', '', '', '', '', '9 a 5 L-V', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(38, 'SANDYS', '', '333612-5080', '', '', '', 'PEDRO MORENO', '1253', '', 'AGUA BLANCA INDUSTRIAL', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(39, 'SEGURIEXPRESS', '', '333686-6605', '', '', '', 'AV. PROL. TEPEYAC', '2360', '', 'MARIANO OTERO', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(40, 'SEGURIFACIL', '', '333811-9971', '106', '', '', 'AV. 8 DE JULIO', '2836 A', '', '18 DE MARZO', '', '', '', '8:30 a 2 y 3 a 6', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(41, 'SERITODO', '', '333614 9847', '', '', '', 'NUEVA GALICIA', '1039', '', 'ZONA CENTRO', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(42, 'SIHPAC', '', '01 228 840 1608', '', '', '', 'ENCINO', '18', '', 'EL OLMO', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(43, 'SIMI ', '', '', '', '', '', 'AV SANTA MARGARITA', '3333', '', 'LOS GIRASOLES 4', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(44, 'SIMILARES', '', '', '', '', '', 'ALEMANIA', '10', '', 'INDEPENDENCIA', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(45, 'STEREN', '', '', '', '', '', 'ENRIQUE LADRON DE GUEVARA', '2898', '', 'PASEOS DEL SOL 1A SECCION', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-02-07 23:28:44'),
(46, 'TRIFUEGO', '', '331578-9038', '', '', '', 'ENCINO', '1420', '', 'DEL FRESNO', '', '', '', '', 'cheque fanny 22 dias/remmex 15 dias', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-03-01 13:37:34'),
(47, 'VIDRIERA PRESIDENCIA', '', '333633-7802', '', '', '', 'PINO SUAREZ', '437', '', 'CENTRO', '', '', '', '', '', '', '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-03-01 13:37:38'),
(48, 'COLORGRAF', '', NULL, NULL, NULL, NULL, NULL, NULL, '', NULL, '', NULL, NULL, NULL, NULL, NULL, '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-03-01 13:37:42'),
(49, 'FARM ARMO', '', NULL, NULL, NULL, NULL, NULL, NULL, '', NULL, '', NULL, NULL, NULL, NULL, NULL, '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-03-01 13:37:46'),
(50, 'GAS-PRO', '', NULL, NULL, NULL, NULL, NULL, NULL, '', NULL, '', NULL, NULL, NULL, NULL, NULL, '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-03-01 13:37:50'),
(51, 'GRUPO REFINSA', '', NULL, NULL, NULL, NULL, NULL, NULL, '', NULL, '', NULL, NULL, NULL, NULL, NULL, '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-03-01 13:38:09'),
(52, 'GSG', '', NULL, NULL, NULL, NULL, NULL, NULL, '', NULL, '', NULL, NULL, NULL, NULL, NULL, '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-03-01 13:37:54'),
(53, 'GPORTHOPEDIC', '', NULL, NULL, NULL, NULL, NULL, NULL, '', NULL, '', NULL, NULL, NULL, NULL, NULL, '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-03-01 13:37:59'),
(54, 'IMCOPAR', '', NULL, NULL, NULL, NULL, NULL, NULL, '', NULL, '', NULL, NULL, NULL, NULL, NULL, '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-03-01 13:38:13'),
(55, 'KANVA ', '', NULL, NULL, NULL, NULL, NULL, NULL, '', NULL, '', NULL, NULL, NULL, NULL, NULL, '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-03-01 13:38:16'),
(56, 'MEXTRAN', '', NULL, NULL, NULL, NULL, NULL, NULL, '', NULL, '', NULL, NULL, NULL, NULL, NULL, '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-03-01 13:38:19'),
(57, 'SMAL', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', NULL, '', NULL, NULL, NULL, NULL, NULL, '', '', '', '', 1, '2022-02-07 23:28:44', 1, '2022-03-01 13:48:27');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proveedores_giros`
--

CREATE TABLE `proveedores_giros` (
  `Id_PG` bigint(20) UNSIGNED NOT NULL,
  `Id_Proveedor` bigint(20) UNSIGNED DEFAULT NULL,
  `Id_Giro` bigint(20) UNSIGNED DEFAULT NULL,
  `UCrea` bigint(20) UNSIGNED DEFAULT NULL,
  `FCrea` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `UAct` bigint(20) UNSIGNED DEFAULT NULL,
  `FAct` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `proveedores_giros`
--

INSERT INTO `proveedores_giros` (`Id_PG`, `Id_Proveedor`, `Id_Giro`, `UCrea`, `FCrea`, `UAct`, `FAct`) VALUES
(1, 1, 1, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(2, 2, 2, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(3, 3, 3, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(4, 4, 4, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(5, 5, 5, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(6, 6, 6, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(7, 7, 7, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(8, 8, 8, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(9, 9, 9, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(10, 10, 10, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(11, 11, 11, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(12, 11, 12, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(13, 12, 4, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(14, 13, 7, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(15, 14, 13, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(16, 15, 2, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(17, 16, 14, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(18, 17, 7, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(19, 18, 15, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(20, 19, 16, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(21, 20, 17, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(22, 21, 18, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(23, 22, 19, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(24, 23, 7, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(25, 24, 7, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(26, 25, 2, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(27, 26, 20, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(28, 26, 21, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(29, 27, 22, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(30, 27, 23, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(31, 28, 24, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(32, 29, 25, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(33, 30, 24, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(34, 31, 4, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(35, 32, 26, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(36, 33, 27, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(37, 34, 7, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(38, 35, 28, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(39, 36, 29, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(40, 36, 30, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(41, 37, 31, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(42, 38, 7, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(43, 39, 7, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(44, 40, 7, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(45, 41, 32, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(46, 42, 33, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(47, 43, 24, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(48, 44, 24, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(49, 45, 7, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(50, 46, 20, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(51, 46, 2, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(52, 47, 34, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(53, 48, 7, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(54, 49, 7, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(55, 50, 7, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(56, 51, 7, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(57, 52, 7, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(58, 53, 7, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(59, 54, 7, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(60, 55, 7, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(61, 56, 7, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37'),
(62, 57, 7, 1, '2022-02-07 23:27:05', 1, '2022-02-07 23:27:37');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `proveedores_tipo_giro`
--

CREATE TABLE `proveedores_tipo_giro` (
  `Id_Giro` bigint(20) UNSIGNED NOT NULL,
  `GIRO` varchar(50) COLLATE utf8_spanish_ci DEFAULT NULL,
  `UCrea` bigint(20) UNSIGNED DEFAULT NULL,
  `FCrea` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `UAct` bigint(20) UNSIGNED DEFAULT NULL,
  `FAct` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `proveedores_tipo_giro`
--

INSERT INTO `proveedores_tipo_giro` (`Id_Giro`, `GIRO`, `UCrea`, `FCrea`, `UAct`, `FAct`) VALUES
(1, 'ACRILICOS', 1, '2022-02-07 23:30:04', 1, NULL),
(2, 'EXTINTORES', 1, '2022-02-07 23:30:04', 1, NULL),
(3, 'CINTA DOBLE CARA', 1, '2022-02-07 23:30:04', 1, NULL),
(4, 'SEÑALAMIENTOS', 1, '2022-02-07 23:30:04', 1, NULL),
(5, 'BORDADOS', 1, '2022-02-07 23:30:04', 1, NULL),
(6, 'VERIFICACION BASCULA', 1, '2022-02-07 23:30:04', 1, NULL),
(7, 'VARIOS', 1, '2022-02-07 23:30:04', 1, NULL),
(8, 'ART. LIMPIEZA', 1, '2022-02-07 23:30:04', 1, NULL),
(9, 'PAQUETERIA', 1, '2022-02-07 23:30:04', 1, NULL),
(10, 'MAT. PROTECTOR TRANS', 1, '2022-02-07 23:30:04', 1, NULL),
(11, 'PELICULA P/FLEJAR', 1, '2022-02-07 23:30:04', 1, NULL),
(12, 'CINTAS', 1, '2022-02-07 23:30:04', 1, NULL),
(13, 'ORINGS', 1, '2022-02-07 23:30:04', 1, NULL),
(14, 'FERRETERIA', 1, '2022-02-07 23:30:04', 1, NULL),
(15, 'PINTURAS', 1, '2022-02-07 23:30:04', 1, NULL),
(16, 'NITROGENO', 1, '2022-02-07 23:30:04', 1, NULL),
(17, 'IMPRESIONES', 1, '2022-02-07 23:30:04', 1, NULL),
(18, 'MONOMETROS GLICERINA', 1, '2022-02-07 23:30:04', 1, NULL),
(19, 'BRAZALETES', 1, '2022-02-07 23:30:04', 1, NULL),
(20, 'ALARMA', 1, '2022-02-07 23:30:04', 1, NULL),
(21, 'PANELES', 1, '2022-02-07 23:30:04', 1, NULL),
(22, 'CHIFLON', 1, '2022-02-07 23:30:04', 1, NULL),
(23, 'VALVULA', 1, '2022-02-07 23:30:04', 1, NULL),
(24, 'MATERIAL DE CURACION', 1, '2022-02-07 23:30:04', 1, NULL),
(25, 'PH MANGUERA IND', 1, '2022-02-07 23:30:04', 1, NULL),
(26, 'VINIL AUTOADHERIBLE', 1, '2022-02-07 23:30:04', 1, NULL),
(27, 'PLASTICOS', 1, '2022-02-07 23:30:04', 1, NULL),
(28, 'LAMPARAS EMERGENCIA', 1, '2022-02-07 23:30:04', 1, NULL),
(29, 'CUBREBOCAS', 1, '2022-02-07 23:30:04', 1, NULL),
(30, 'SANITIZANTE', 1, '2022-02-07 23:30:04', 1, NULL),
(31, 'REGULADOR P/TANQUE NITROG', 1, '2022-02-07 23:30:04', 1, NULL),
(32, 'MARCOS DE MEYER', 1, '2022-02-07 23:30:04', 1, NULL),
(33, 'CHALECOS', 1, '2022-02-07 23:30:04', 1, NULL),
(34, 'VIDRIOS', 1, '2022-02-07 23:30:04', 1, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sucursales`
--

CREATE TABLE `sucursales` (
  `Id_Sucursal` bigint(20) UNSIGNED NOT NULL,
  `Nombre_sucursal` varchar(100) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Id_Encargado` bigint(20) UNSIGNED DEFAULT NULL,
  `Calle` varchar(100) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Numero` varchar(20) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Colonia` varchar(50) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Municipio` varchar(50) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Estado` varchar(50) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Pais` varchar(50) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Tel1` varchar(20) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Ext1` varchar(10) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Tel2` varchar(20) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Ext2` varchar(10) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Matriz` tinyint(1) DEFAULT NULL,
  `Latitud` double DEFAULT NULL,
  `Longitud` double DEFAULT NULL,
  `Observaciones` text COLLATE utf8_spanish_ci,
  `UCrea` bigint(20) UNSIGNED DEFAULT NULL,
  `FCrea` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `UAct` bigint(20) UNSIGNED DEFAULT NULL,
  `FAct` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sucursal_personal`
--

CREATE TABLE `sucursal_personal` (
  `Id_SP` bigint(20) UNSIGNED NOT NULL,
  `Id_Empleado` bigint(20) UNSIGNED DEFAULT NULL,
  `Id_Sucursal` bigint(20) UNSIGNED DEFAULT NULL,
  `Posicion` varchar(50) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Encargado` tinyint(1) DEFAULT NULL,
  `UCrea` bigint(20) UNSIGNED DEFAULT NULL,
  `FCrea` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `UAct` bigint(20) UNSIGNED DEFAULT NULL,
  `FAct` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

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
-- Indices de la tabla `productos`
--
ALTER TABLE `productos`
  ADD PRIMARY KEY (`Id_Producto`),
  ADD KEY `fk_produc_tipo` (`Tipo`),
  ADD KEY `fk_ucrea_produc` (`UCrea`),
  ADD KEY `fk_uact_produc` (`UAct`);

--
-- Indices de la tabla `productos_proveedores`
--
ALTER TABLE `productos_proveedores`
  ADD PRIMARY KEY (`Id_PP`),
  ADD KEY `fk_idproduc_producs` (`Id_Producto`),
  ADD KEY `fk_ucrea_pp` (`UCrea`),
  ADD KEY `fk_uact_pp` (`UAct`),
  ADD KEY `Id_Proveedor` (`Id_Proveedor`);

--
-- Indices de la tabla `productos_tipos`
--
ALTER TABLE `productos_tipos`
  ADD PRIMARY KEY (`Id_Tipo`),
  ADD UNIQUE KEY `Tipo` (`Tipo`),
  ADD KEY `fk_ucrea_tipo` (`UCrea`),
  ADD KEY `fk_uact_tipo` (`UAct`);

--
-- Indices de la tabla `proveedores`
--
ALTER TABLE `proveedores`
  ADD PRIMARY KEY (`Id_Proveedor`),
  ADD KEY `fk_ucrea_prov` (`UCrea`),
  ADD KEY `fk_uact_prov` (`UAct`);

--
-- Indices de la tabla `proveedores_giros`
--
ALTER TABLE `proveedores_giros`
  ADD PRIMARY KEY (`Id_PG`),
  ADD KEY `fk_ucrea_pg` (`UCrea`),
  ADD KEY `fk_uact_pg` (`UAct`),
  ADD KEY `fk_idprov_provs` (`Id_Proveedor`),
  ADD KEY `fk_idgiro_giros` (`Id_Giro`);

--
-- Indices de la tabla `proveedores_tipo_giro`
--
ALTER TABLE `proveedores_tipo_giro`
  ADD PRIMARY KEY (`Id_Giro`),
  ADD UNIQUE KEY `GIRO` (`GIRO`),
  ADD KEY `fk_ucrea_giros` (`UCrea`),
  ADD KEY `fk_uact_giros` (`UAct`);

--
-- Indices de la tabla `sucursales`
--
ALTER TABLE `sucursales`
  ADD PRIMARY KEY (`Id_Sucursal`),
  ADD KEY `fk_ucrea_suc` (`UCrea`),
  ADD KEY `fk_uact_suc` (`UAct`),
  ADD KEY `fk_encargado_suc` (`Id_Encargado`);

--
-- Indices de la tabla `sucursal_personal`
--
ALTER TABLE `sucursal_personal`
  ADD PRIMARY KEY (`Id_SP`),
  ADD UNIQUE KEY `Id_Empleado` (`Id_Empleado`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `accesos`
--
ALTER TABLE `accesos`
  MODIFY `Id_Acceso` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=97;

--
-- AUTO_INCREMENT de la tabla `fuentes`
--
ALTER TABLE `fuentes`
  MODIFY `Id_Fuente` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `links`
--
ALTER TABLE `links`
  MODIFY `Id_Link` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT de la tabla `modulos`
--
ALTER TABLE `modulos`
  MODIFY `Id_Modulo` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `modulos_grupo`
--
ALTER TABLE `modulos_grupo`
  MODIFY `Id_Grupo` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `multimedia`
--
ALTER TABLE `multimedia`
  MODIFY `Id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

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
-- AUTO_INCREMENT de la tabla `productos`
--
ALTER TABLE `productos`
  MODIFY `Id_Producto` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1150;

--
-- AUTO_INCREMENT de la tabla `productos_proveedores`
--
ALTER TABLE `productos_proveedores`
  MODIFY `Id_PP` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `productos_tipos`
--
ALTER TABLE `productos_tipos`
  MODIFY `Id_Tipo` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `proveedores`
--
ALTER TABLE `proveedores`
  MODIFY `Id_Proveedor` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=61;

--
-- AUTO_INCREMENT de la tabla `proveedores_giros`
--
ALTER TABLE `proveedores_giros`
  MODIFY `Id_PG` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=64;

--
-- AUTO_INCREMENT de la tabla `proveedores_tipo_giro`
--
ALTER TABLE `proveedores_tipo_giro`
  MODIFY `Id_Giro` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=35;

--
-- AUTO_INCREMENT de la tabla `sucursales`
--
ALTER TABLE `sucursales`
  MODIFY `Id_Sucursal` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `sucursal_personal`
--
ALTER TABLE `sucursal_personal`
  MODIFY `Id_SP` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

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

--
-- Filtros para la tabla `productos`
--
ALTER TABLE `productos`
  ADD CONSTRAINT `fk_produc_tipo` FOREIGN KEY (`Tipo`) REFERENCES `productos_tipos` (`Id_Tipo`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_uact_produc` FOREIGN KEY (`UAct`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ucrea_produc` FOREIGN KEY (`UCrea`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Filtros para la tabla `productos_proveedores`
--
ALTER TABLE `productos_proveedores`
  ADD CONSTRAINT `fk_idp_provs` FOREIGN KEY (`Id_Proveedor`) REFERENCES `proveedores` (`Id_Proveedor`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_idproduc_producs` FOREIGN KEY (`Id_Producto`) REFERENCES `productos` (`Id_Producto`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_uact_pp` FOREIGN KEY (`UAct`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ucrea_pp` FOREIGN KEY (`UCrea`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Filtros para la tabla `productos_tipos`
--
ALTER TABLE `productos_tipos`
  ADD CONSTRAINT `fk_uact_tipo` FOREIGN KEY (`UAct`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ucrea_tipo` FOREIGN KEY (`UCrea`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Filtros para la tabla `proveedores`
--
ALTER TABLE `proveedores`
  ADD CONSTRAINT `fk_uact_prov` FOREIGN KEY (`UAct`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ucrea_prov` FOREIGN KEY (`UCrea`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Filtros para la tabla `proveedores_giros`
--
ALTER TABLE `proveedores_giros`
  ADD CONSTRAINT `fk_idgiro_giros` FOREIGN KEY (`Id_Giro`) REFERENCES `proveedores_tipo_giro` (`Id_Giro`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_idprov_provs` FOREIGN KEY (`Id_Proveedor`) REFERENCES `proveedores` (`Id_Proveedor`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_uact_pg` FOREIGN KEY (`UAct`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ucrea_pg` FOREIGN KEY (`UCrea`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Filtros para la tabla `proveedores_tipo_giro`
--
ALTER TABLE `proveedores_tipo_giro`
  ADD CONSTRAINT `fk_uact_giros` FOREIGN KEY (`UAct`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ucrea_giros` FOREIGN KEY (`UCrea`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Filtros para la tabla `sucursales`
--
ALTER TABLE `sucursales`
  ADD CONSTRAINT `fk_encargado_suc` FOREIGN KEY (`Id_Encargado`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_uact_suc` FOREIGN KEY (`UAct`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ucrea_suc` FOREIGN KEY (`UCrea`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE SET NULL ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
