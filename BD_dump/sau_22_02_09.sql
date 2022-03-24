-- phpMyAdmin SQL Dump
-- version 5.1.1
-- https://www.phpmyadmin.net/
--
-- Servidor: localhost:3306
-- Tiempo de generación: 09-02-2022 a las 18:05:17
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
            a.Dispositivo,
            a.Latitud,
            a.Longitud
        FROM accesos a
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `login` (IN `_nick` VARCHAR(50), IN `_pass` VARCHAR(50), IN `_disp` VARCHAR(30), IN `_lat` VARCHAR(50), IN `_lng` VARCHAR(50))  BEGIN
SET @id   = NULL;
SET @acc  = 0;
SET @disp = NULL;
SET @lat  = NULL;
SET @lng  = NULL;
SET @@session.block_encryption_mode = 'aes-256-ecb';

#Se comprueban los valores de disp
IF LENGTH(_disp)>0 OR NOT _disp IS NULL THEN
	SET @disp = _disp;
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
   	Dispositivo,
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
       AND m.Tipo_archivo LIKE 'FPresentacion'
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
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `logout` (IN `_nick` VARCHAR(50), IN `_disp` VARCHAR(30), IN `_lat` VARCHAR(50), IN `_lng` VARCHAR(50))  BEGIN
SET @id = NULL;
SET @acc = 0;
SET @disp = NULL;
SET @lat  = NULL;
SET @lng  = NULL;

#Se comprueban los valores de disp
IF LENGTH(_disp)>0 OR NOT _disp IS NULL THEN
	SET @disp = _disp;
END IF;

#Se comprueban los valores de lat
IF LENGTH(_lat)>0 OR NOT _lat IS NULL THEN
	SET @lat = _lat;
END IF;

#Se comprueban los valores de lng
IF LENGTH(_lng)>0 OR NOT _lng IS NULL THEN
	SET @lng = _lng;
END IF;

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
   	Dispositivo,
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
  `Dispositivo` varchar(30) COLLATE utf8_spanish_ci DEFAULT NULL,
  `Latitud` double DEFAULT NULL,
  `Longitud` double DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `accesos`
--

INSERT INTO `accesos` (`Id_Acceso`, `Id_Usuario`, `Tipo_Acceso`, `Fecha`, `Dispositivo`, `Latitud`, `Longitud`) VALUES
(1, 1, 'LOGIN', '2022-01-06 16:04:23', 'WEB', 0, 0),
(2, 1, 'LOGOUT', '2022-01-06 16:07:10', 'WEB', 0, 0),
(3, 1, 'LOGIN', '2022-01-15 04:39:37', 'WEB', 0, 0),
(4, 2, 'LOGIN', '2022-01-26 18:25:13', 'POSTMAN', 0, 0),
(5, 2, 'LOGIN', '2022-01-26 18:25:59', 'POSTMAN', 0, 0),
(6, 2, 'LOGIN', '2022-01-26 18:29:39', 'POSTMAN', 0, 0),
(7, 2, 'LOGIN', '2022-01-26 18:30:05', 'BD', 0, 0),
(8, 2, 'LOGIN', '2022-01-26 18:35:41', 'POSTMAN', 0, 0),
(9, 2, 'LOGIN', '2022-01-26 18:41:59', 'POSTMAN', 0, 0),
(10, 2, 'LOGIN', '2022-01-26 18:42:39', 'POSTMAN', 0, 0),
(11, 2, 'LOGIN', '2022-01-26 18:43:51', 'POSTMAN', 0, 0),
(12, 2, 'LOGIN', '2022-01-26 18:45:08', 'POSTMAN', 0, 0),
(13, 2, 'LOGIN', '2022-01-26 18:46:18', 'POSTMAN', 0, 0),
(14, 2, 'LOGIN', '2022-01-26 18:46:43', 'POSTMAN', 0, 0),
(15, 2, 'LOGIN', '2022-01-26 18:47:12', 'POSTMAN', 0, 0),
(16, 2, 'LOGIN', '2022-01-26 18:47:31', 'POSTMAN', 0, 0),
(17, 2, 'LOGIN', '2022-01-26 18:51:10', 'POSTMAN', 0, 0),
(18, 2, 'LOGIN', '2022-01-26 18:51:45', 'POSTMAN', 0, 0),
(19, 2, 'LOGOUT', '2022-01-26 19:10:16', 'POSTMAN', 0, 0),
(20, 2, 'LOGOUT', '2022-01-26 19:12:27', 'POSTMAN', 0, 0),
(21, 2, 'LOGOUT', '2022-01-26 19:12:40', 'POSTMAN', 0, 0),
(22, 2, 'LOGIN', '2022-01-26 19:16:38', 'POSTMAN', 0, 0),
(23, 2, 'LOGIN', '2022-01-26 19:16:56', 'POSTMAN', 0, 0),
(24, 2, 'LOGOUT', '2022-01-26 19:17:00', 'POSTMAN', 0, 0),
(25, 2, 'LOGIN', '2022-01-26 19:26:36', 'POSTMAN', 0, 0),
(26, 2, 'LOGIN', '2022-02-07 20:01:25', 'POSTMAN', 0, 0),
(27, 1, 'LOGIN', '2022-02-07 20:01:45', 'POSTMAN', 0, 0),
(28, 1, 'LOGIN', '2022-02-07 20:06:20', 'POSTMAN', 0, 0),
(29, 1, 'LOGOUT', '2022-02-07 20:06:27', 'POSTMAN', 0, 0),
(30, 1, 'LOGIN', '2022-02-07 20:08:24', 'POSTMAN', 0, 0);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `links`
--

CREATE TABLE `links` (
  `Id_Link` bigint(20) UNSIGNED NOT NULL,
  `Id_Usuario` bigint(20) UNSIGNED NOT NULL,
  `Id_Modulo` bigint(20) UNSIGNED NOT NULL,
  `Escritura` tinyint(1) DEFAULT '0',
  `UCrea` bigint(20) UNSIGNED NOT NULL,
  `FCrea` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `UAct` bigint(20) UNSIGNED DEFAULT NULL,
  `FAct` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `links`
--

INSERT INTO `links` (`Id_Link`, `Id_Usuario`, `Id_Modulo`, `Escritura`, `UCrea`, `FCrea`, `UAct`, `FAct`) VALUES
(2, 2, 2, 0, 1, '2022-01-06 16:24:47', NULL, '2022-01-06 16:24:47'),
(3, 3, 3, 1, 1, '2022-01-06 16:24:47', NULL, '2022-01-06 16:24:47'),
(5, 2, 3, 0, 1, '2022-02-03 19:52:50', NULL, '2022-02-03 19:52:50');

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
(3, 'Captura_capturista', 'nauta.test/captura/captura', 2, 1, '2022-01-06 16:23:38', 1, '2022-01-20 20:55:11');

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
(3, 'PERFIL', '14-perfil', 'C:/laragon/www/nauta/multimedia/14/14-perfil.jpg', 'nauta.test/multimedia/14/14-perfil.jpg', NULL, 'navegantes', '14', 1, '2022-02-03 19:20:18', NULL, '2022-02-03 19:20:18');

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
(1, 'P', 'm', 'n', 'ni', 0x622dac7690cf158c28d9237ef99541b6, 'DEVELOPER', 1, 1, '146b1ea64459827d9fadd724e88ced58a7da7c5b', NULL, '2022-01-06 01:35:31', NULL, '2022-02-07 20:08:24'),
(2, 'P2', 'm2', 'n2', 'ni2', 0x8e538e7d01c13b5d9257ea6ad3f51a5b, 'SUPERVISOR_CAPTURA', 1, 1, '7fe43139f0e73812c197ef064d548b4be4c0b993', NULL, '2022-01-06 01:35:43', NULL, '2022-02-07 20:01:25'),
(3, 'P3', 'm3', 'n3', 'ni3', 0xf4cb67671450ca9f14bacaa31ec8ca6a, 'CAPTURISTA', 1, -1, NULL, NULL, '2022-01-06 01:35:54', NULL, '2022-02-07 20:16:16'),
(14, 'Prueba', 'Crear', 'Usuario', 'TEST', 0xad88950be1eb8a698c7bf988c2d8a848, NULL, 1, -1, NULL, NULL, '2022-02-03 18:59:17', NULL, '2022-02-03 18:59:17');

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
  ADD KEY `fk_usuario_acc` (`Id_Usuario`);

--
-- Indices de la tabla `links`
--
ALTER TABLE `links`
  ADD PRIMARY KEY (`Id_Link`),
  ADD KEY `fk_usuario_link` (`Id_Usuario`),
  ADD KEY `fk_modulo_link` (`Id_Modulo`),
  ADD KEY `fk_ucrea_link` (`UCrea`),
  ADD KEY `fk_uact_link` (`UAct`);

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
  MODIFY `Id_Acceso` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

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
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `accesos`
--
ALTER TABLE `accesos`
  ADD CONSTRAINT `fk_usuario_acc` FOREIGN KEY (`Id_Usuario`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Filtros para la tabla `links`
--
ALTER TABLE `links`
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
-- Filtros para la tabla `navegantes_niveles`
--
ALTER TABLE `navegantes_niveles`
  ADD CONSTRAINT `fk_uact_univeles` FOREIGN KEY (`UAct`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE NO ACTION ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ucrea_univeles` FOREIGN KEY (`UCrea`) REFERENCES `navegantes` (`Id_Usuario`) ON DELETE NO ACTION ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
