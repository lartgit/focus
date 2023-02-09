
BEGIN;

-- Por ahora lo dejo comentado ya que no se si hay alguna forma de insertar los srid desde los datos que me mandan.

-- Este es el srid del shape de los lotes que mandaron de ejemplo
-- lo busque y baje de: http://spatialreference.org/ref/epsg/22175/
INSERT into spatial_ref_sys (srid, auth_name, auth_srid, proj4text, srtext)
    values ( 922175, 'epsg', 22175, '+proj=tmerc +lat_0=-90 +lon_0=-60 +k=1 +x_0=5500000 +y_0=0 +ellps=GRS80 +units=m +no_defs ',
    'PROJCS["POSGAR 98 / Argentina 5",GEOGCS["POSGAR 98",DATUM["Posiciones_Geodesicas_Argentinas_1998",SPHEROID["GRS 1980",6378137,298.257222101,AUTHORITY["EPSG","7019"]],AUTHORITY["EPSG","6190"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.01745329251994328,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4190"]],UNIT["metre",1,AUTHORITY["EPSG","9001"]],PROJECTION["Transverse_Mercator"],PARAMETER["latitude_of_origin",-90],PARAMETER["central_meridian",-60],PARAMETER["scale_factor",1],PARAMETER["false_easting",5500000],PARAMETER["false_northing",0],AUTHORITY["EPSG","22175"],AXIS["Y",EAST],AXIS["X",NORTH]]');

--  Este srid lo saque del raster que tengo de ejemplo
INSERT into spatial_ref_sys (srid, auth_name, auth_srid, proj4text, srtext)
    values ( 9001, 'EPSG', 9001, '+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +a=6371007.181 +b=6371007.181 +units=m +no_defs',
    'PROJCS["unnamed", GEOGCS["Unknown datum based upon the custom spheroid", DATUM["Not_specified_based_on_custom_spheroid", SPHEROID["Custom spheroid",6371007.181,0]], PRIMEM["Greenwich",0], UNIT["degree",0.0174532925199433]], PROJECTION["Sinusoidal"], PARAMETER["longitude_of_center",0], PARAMETER["false_easting",0], PARAMETER["false_northing",0], UNIT["metre",1, AUTHORITY["EPSG","9001"]]]');

COMMIT;
