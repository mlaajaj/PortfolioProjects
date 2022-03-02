-- A la découverte de notre jeux de données 

SELECT *
FROM paris
LIMIT 10;

SELECT COUNT(*)
FROM paris;

------------------------------------------------------------------------------------------------------------

				--- PARTIE DATA CLEANING - Explortion ---


-- 1. Commençons par la colonne device_portal_format qui indique le type d'appareil connecté

SELECT distinct device_portal_format
FROM paris;
	
	-- Données à corriger : Tablet en Tablette et Computer en Ordinateur pour se retrouver avec 3 variables : Mobile, Tablette et Ordinateur.

SELECT 
	distinct device_portal_format, 
	CASE device_portal_format
	when 'Tablet' then 'Tablette'
	when 'Computer' then 'Ordinateur'
	else device_portal_format
	end as device
FROM paris;

-- Créons donc une nouvelle colonne "device"
ALTER TABLE paris
ADD device as (
	CASE device_portal_format
	when 'Tablet' then 'Tablette'
	when 'Computer' then 'Ordinateur'
	else device_portal_format
	end); 

-- Nous aurions pu également changer la colonne via alter table puis update. Je préfère partir sur une nouvelle colonne.

SELECT distinct device
FROM paris;

------------------------------------------------------------------------------------------------------------

-- 2. Colonne device_constructor_name qui indique le nom du constructeur de l'appareil 
SELECT DISTINCT device_constructor_name
from paris;
	-- Autre et other = même chose 
ALTER TABLE paris
ADD marque as (
	CASE device_constructor_name
	when 'other' then 'Autre'
	when 'autre' then 'Autre'
	else device_constructor_name
	end); 	
	
SELECT distinct marque
from paris;
	

------------------------------------------------------------------------------------------------------------

-- 3. Colonne device_browser_name_version = correspond au navigateur utilisé 

select distinct device_browser_name_version
from paris;
 
	-- Example d'output : "Chrome 76.0" 
	-- Nous avons des informations concernant la version des navigateurs, cela peut être intéressant mais nous allons plutôt nous concentrer sur le nom du navigateur en lui même.
	-- c-a-d le premier mot "Safari", "Chrome"...
	
ALTER TABLE paris
ADD navigateur as (
	case 
	when device_browser_name_version = 'unknown' or device_browser_name_version = 'inconnu' or device_browser_name_version = "" then 'Inconnu'
	else substr(device_browser_name_version, 1, instr(device_browser_name_version, ' ') -1)
	end
) 
	
select distinct navigateur 
from paris;

------------------------------------------------------------------------------------------------------------

-- 4. Langue d'utilisation
	
SELECT
	distinct userlanguage
from paris;	
	
ALTER TABLE paris
ADD langue as (
	CASE userlanguage
	when "Tha‹landais" then "Thaïlandais"
	when "N‚erlandais" then "Néerlandais"
	when "Indon‚sien" then "Indonésien"
	when "Cor‚en" then "Coréen"
	when "Fran‡ais" then "Français"
	when "Chinois simplifié" then "Chinois"
	when "Chinois simplifi‚" then "Chinois"
	when "Chinois traditionnel" then "Chinois"
	when "" then "Inconnu"	when "#N/A" then "Inconnu"
	else userlanguage
	end )
	
select count(distinct userlanguage)
from paris;	
	
SELECT count(distinct langue)
from paris;
	
------------------------------------------------------------------------------------------------------------
	
-- 5.Les noms de site 

Select substr(nom_site, 1, instr(nom_site," ") -1), round(1. * count(*)/(select count(*) from paris),2)
from paris
group by substr(nom_site, 1, instr(nom_site," ") -1)
having round(1. * count(*)/(select count(*) from paris),2) > 0.03  ;	

	

ALTER TABLE paris 
add emplacement as (substr(nom_site, 1, instr(nom_site," ") -1)) ; 

select distinct emplacement_ok
from paris;

------------------------------------------------------------------------------------------------------------

-- 6. Dates et jours de la semaine 

ALTER TABLE paris
ADD jour_semaine as (  
  case cast (strftime('%w', datetime) as integer)
  when 0 then 'Dimanche'
  when 1 then 'Lundi'
  when 2 then 'Mardi'
  when 3 then 'Mercredi'
  when 4 then 'Jeudi'
  when 5 then 'Vendredi'
  else 'Samedi' 
  end )

------------------------------------------------------------------------------------------------------------

				--- PARTIE ANALYSE ---

-- Vue d'ensemble de notre dataset et de nos variables. 
select *
from paris_temp
limit 10;


-- Quel type d'appareil est majoritaire ? 
select device, count(device) as Total, round( 1. * count(device)/(select count(device) from paris),3) as Pourcentage
from paris_temp 
group by device; 
	-- 78% des connexions se font via Mobile
	
-- Pour les mobiles, quelle marque est majoritaire ? 
select marque, count(marque) as Total, round( 1. * count(marque)/(select count(marque) from paris),3) as Pourcentage
from paris_temp 
where device = 'Mobile'
group by marque; 	


-- Quelle marque est majoritaire (tout appareil confondu) ? 
SELECT marque, count(marque) as Total, round(1. * count(marque)/(select count(marque) from paris),3) as Pourcentage
FROM paris	
group by marque
order by Pourcentage desc ;
	-- 35% des appareils connectés proviennent de la marque Apple 
	

-- Quels appareils sont les utilisés pour chaque marque ? 
with p as (
select marque, count(*) as Tot
from paris
group by marque)
SELECT a.marque, a.device, count(a.device) as Total, round(1.0 * count(a.device)/(p.Tot),3) as Pourcentage
from paris as a 
inner join p on 
a.marque = p.marque
group by a.marque, a.device
order by a.marque	
	-- Les smartphones (Iphone) représentent 73% des appareils de la marque Apple puis nous avons 24% d'ordinateur. Concernant Samsung, on est à 99% de smartphones

-- Navigateurs 
SELECT navigateur, count(navigateur) as Total, round(1. * count(navigateur)/(select count(navigateur) from paris),3) as Pourcentage
from paris 
group by navigateur 

	-- Le navigateur le plus utilisé est Chrome avec 53% d'utilisation
	-- Regardons le navigateur le plus utilisé par type d'appareil 
	
with p as (
select device, count(device) as Tot
from paris 
group by device)	
SELECT a.device, a.navigateur, count(a.navigateur) as Total, round(1. * count(a.navigateur) / p.Tot,2) as Pourcentage
from paris as a 
INNER JOIN p 
ON a.device = p.device
group by a.device, a.navigateur;

	-- Sur téléphone, on a Chrome qui est devant mais Safari reste très proche par contre sur Ordinateur, Chrome est loin devant avec Firefox. 


select emplacement, avg(temps_de_sessions_en_minutes), avg(donnee_entrante_go), avg(donnee_sortante_gigaoctet),
round(1. * count(*)/(select count(*) from paris_temp),2) as Pourcentage
from paris_temp
group by emplacement;

select device, avg(temps_de_sessions_en_minutes), avg(donnee_entrante_go), avg(donnee_sortante_gigaoctet),
round(1. * count(*)/(select count(*) from paris_temp),2) as Pourcentage
from paris_temp
group by device;

select navigateur, avg(temps_de_sessions_en_minutes), avg(donnee_entrante_go), avg(donnee_sortante_gigaoctet),
round(1. * count(*)/(select count(*) from paris_temp),2) as Pourcentage
from paris_temp
group by navigateur
having pourcentage >0;

select langue, avg(temps_de_sessions_en_minutes), avg(donnee_entrante_go), avg(donnee_sortante_gigaoctet),
round(1. * count(*)/(select count(*) from paris_temp),2) as Pourcentage
from paris_temp
group by langue
having pourcentage >0;

select jour_semaine, avg(temps_de_sessions_en_minutes), avg(donnee_entrante_go), avg(donnee_sortante_gigaoctet),
round(1. * count(*)/(select count(*) from paris_temp),2) as Pourcentage
from paris_temp
group by jour_semaine
having pourcentage >0;

select jour_semaine, count(*)/7 as Moyenne
from paris_temp
group by jour_semaine;

select jour_semaine,langue,
round(1. * count(*)/(select count(*) from paris_temp),4) as Pourcentage
from paris_temp
group by jour_semaine, langue;

with p as (
select emplacement, count(*) as Tot
from paris_temp 
group by emplacement )
select a.emplacement, a.marque, round(1.0 * count(a.emplacement)/p.Tot,2) as Pourcentage
from paris_temp as a 
inner join p on a.emplacement = p.emplacement
group by a.emplacement, a.marque;

select emplacement, datetime, strftime('%Y', datetime) as Year, strftime('%m', datetime) as Month, strftime('%d', datetime) as Day, jour_semaine, strftime('%H', datetime)+2 as Heure
from paris_temp
where Heure = 25; 

select nom_site, count(*) as Tot
from paris_temp
where strftime('%H', datetime)+2 = 25
group by nom_site; 

select jour_semaine ,
case when strftime('%H', datetime)+2 = 25 then 1
else strftime('%H', datetime)+2 
end as Heure
, count(*) as Tot
from paris_temp
group by jour_semaine, Heure
order by 1,3 desc;
