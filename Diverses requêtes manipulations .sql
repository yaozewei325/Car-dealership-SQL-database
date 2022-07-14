use concessionnaire

select* from VoitureVente
select * from voiture_service
select * from BilletService
select * from Client
select * from Vendeur
select * from FactureAchat
select * from FactureVente
select * from pieces
select * from pieces_utilisees
select * from service
select * from service_rendu


--Section 1 : Validation des données

--Comme les données ont été générées aléatoirement par l'ordinateur, certaines d'entre elles n'ont 
--aucun sens logique même si elles respectent les types de données. Les requêtes suivantes dans section 1 sont pour 
--le but de valider les données afin de les rendre plus logiques.

--1. Dans le table de BilletService, mettre à jour la date à la date actuelle si la date de réception est 
--postérieure à la date de retour
--(Cette opération n'a pas non plus de sens dans la vie réelle, mais elle nous assure que la date de réception
--n'est jamais postérieure à la date de retour dans notre base de données.)

UPDATE BilletService
SET date_de_retour =   CAST(GETDATE() as DATE)
WHERE date_de_reception > date_de_retour;

--Vérifiez-le
SELECT DATEDIFF(DAY, date_de_reception,date_de_retour) FROM BilletService

--2. Trouver le BilletService qui n'a pas de service_rendu correspondant, et les supprimer.
--Parce que billet service a la clé étrangère dans le service rendu, mais il n'y a aucun mécanisme pour garantir dans 
--la création de la table elle-même que chaque billet de service a un service rendu.
--Mais dans la vie réelle, chaque fois qu'il y a une billet de service, il devrait y avoir au moins un service, 
--même sans utiliser de pièces.

SELECT t1.id, t1.num_billet, id_billet_service FROM BilletService as t1
left join service_rendu as t2
on t2.id_billet_service= t1.id
WHERE id_billet_service is null


DELETE FROM BilletService  
WHERE BilletService.id 
in(SELECT BilletService.id FROM BilletService as t1
left join service_rendu as t2
on t2.id_billet_service= t1.id
WHERE id_billet_service is null);

--3.Mettre à jour le prix de vente en (prix de vente + prix d'achat) si le prix de vente est inférieur au prix d'achat. 
--(Cette opération n'a pas non plus de sens dans la vie réelle, mais elle nous assure que le prix de vente n'est jamais 
--inférieur au prix d'achat dans notre base de données.)

UPDATE FactureVente
SET prix = t1.prix + t2.prix
FROM FactureVente as t1
join FactureAchat as t2 on t1.id_voiture = t2.id_voiture
WHERE t2.prix>t1.prix

--Vérifiez-le
SELECT t1.id_voiture, t1.prix as prixVente, t2.prix as prixAchat FROM FactureVente as t1
join FactureAchat as t2 on t1.id_voiture = t2.id_voiture
WHERE t2.prix>t1.prix

--4. Mettre à jour la date d'vente en date du jour si elle est antérieure à la date d'achat.
 

UPDATE FactureVente
SET FactureVente.date =  CAST(GETDATE() as DATE)
FROM FactureVente as t1
join FactureAchat as t2 on t1.id_voiture = t2.id_voiture
WHERE t2.date>t1.date;

--Vérifiez-le
SELECT t1.date as date_vente, t2.date as date_achat FROM FactureVente as t1
join FactureAchat as t2 on t1.id_voiture = t2.id_voiture
WHERE t2.date>t1.date;

--5. Mettre à jour le prix de vente des pièces en (prix de vente + prix d'achat) si le prix de vente est inférieur au prix d'achat. 
UPDATE pieces
SET prix_vente = prix_vente + prix_achat
WHERE prix_vente<prix_achat;

--Vérifiez-le
SELECT * FROM pieces
WHERE prix_achat > prix_vente;


--------------------------------------------------------------------------------------------------------
--Section 2 : Manipuler la base de données en incorporant tous les types de requêtes enseignés dans ce cours.

--1. Trouver les 10 voitures les plus rentables et les classer par ordre décroissant.
SELECT top 10 (t2.prix-t3.prix) as profit , marque, modele FROM VoitureVente as t1
join FactureVente as t2 on t2.id_voiture = t1.id_voiture
join FactureAchat as t3 on t3.id_voiture = t1.id_voiture
ORDER BY profit desc

--2. Trouvez les 10 villes où les clients achètent le plus de voitures.
SELECT top 10 count(t1.id_client) as nbClient, t2.ville FROM FactureVente as t1
join client as t2 
on t1.id_client = t2.id
GROUP BY t2.ville
ORDER BY nbClient desc;
 
--3. Trouvez les 10 modèles qui sont en stock depuis le plus longtemps.
SELECT top 10 marque, modele, datediff(day, t3.date, t2.date) as TempsStockage
FROM VoitureVente as t1
inner join FactureVente as t2
on t1.id_voiture = t2.id_voiture
inner join FactureAchat as t3
on t2.id_voiture=t3.id_voiture
ORDER BY TempsStockage desc


--4.Trouvez les voitures à vendre de la marque Ford qui ont au moins 200 chevaux et 4 portes et qui ont au moins 2 de ces caractéristiques:
--（sièges en cuir, démarrage à distance, toit ouvrant.)
SELECT * FROM VoitureVente
WHERE marque ='ford' And chevaux_vapeur >=200 
  And numero_portes >=4 
  And ((sieges_en_cuir = 1 and demarrage_a_distance = 1) or (demarrage_a_distance=1 and toit_ouvrant =1) or (sieges_en_cuir=1 and toit_ouvrant=1));


--5. Affichez le nombre de modèles par marque qui ont été fabriqués après l'an 2000 et avec une puissance supérieure à 300 chevaux.
SELECT count(modele) as nbModele, marque FROM VoitureVente
WHERE annee>2000
GROUP BY marque
ORDER BY nbModele desc;

--6. Trouvez la liste des marques qui ont au moins 2 modèles avec une puissance supérieure à 400 chevaux.
SELECT marque, count(modele) as nbModele FROM VoitureVente
WHERE chevaux_vapeur >400
GROUP BY marque
having count(modele) >=2
ORDER BY nbModele desc

--7. Calculez le nombre de modele de chaque marque dont la puissance est comprise entre  201..300.
SELECT count(modele)as nbModele, marque FROM VoitureVente
WHERE chevaux_vapeur between 201 and 300
GROUP BY marque
ORDER BY nbModele desc;

--8. Trouvez les modèles qui ont les coûts de service les plus élevés, et les transformer en tables.
SELECT t1.modele, sum(t4.taux*t3.heures) as coutsService  into cout_service FROM voiture_service as t1
join BilletService as t2 on t1.id_voiture = t2.id_voiture
join service_rendu as t3 on t2.id = t3.id_billet_service
join service as t4 on t3.id_service = t4.id
GROUP BY modele
ORDER BY coutsService desc;

select * from cout_service order by coutsService desc;

--9. Trouvez les modèles dont le coût des pièces est le plus élevé,et les transformer en tables.
SELECT t1.modele,sum(t3.quantite*t4.prix_vente) as coutsPieces into cout_piece FROM voiture_service as t1
join BilletService as t2 on t1.id_voiture = t2.id_voiture
join pieces_utilisees as t3 on t2.id = t3.id_billet_service
join pieces as t4 on t3.id = t4.id
GROUP BY modele
ORDER BY coutsPieces desc;

select * from cout_piece order by coutsPieces desc;

--10. Trouvez les top 10 modèles dont les coûts de réparation (service + pièces) sont les plus élevés.

SELECT top 10 t1.modele, t1.coutsService, (coutsPieces+coutsService) as coutTotal FROM cout_service as t1
left join cout_piece as t2 on t1.modele = t2.modele
ORDER BY coutTotal desc;

--assurez-vous que ceux qui n'ont pas de coût de pièces ont un coût de service seul qui ne dépasse pas le coût total des résultats de la recherche précédente. 
SELECT t1.modele, t1.coutsService as coutTotal FROM cout_service as t1
left join cout_piece as t2 on t1.modele = t2.modele
WHERE coutsPieces IS NULL
ORDER BY coutTotal desc;

--11. Trouvez les 10 modèles dont l'entretien est le plus fréquent.
select top 10 t1.modele, count(t2.num_billet) as frequence from voiture_service as t1
join BilletService as t2 on t1.id_voiture = t2.id_voiture
group by modele
order by frequence desc;

--12. Trouvez les 10 services qui ont généré le plus de revenus
select top 10 t1.id, t1.nom, sum(taux*heures) as revenus from service as t1
join service_rendu as t2 on t1.id = t2.id_service
group by t1.id, t1.nom
order by revenus desc;

--13. Trouvez les 10 pièces qui ont généré le plus de profit
select top 10 num_piece, description, sum((prix_vente-prix_achat)*t2.quantite) as profit from pieces as t1
join pieces_utilisees as t2 on t1.id=t2.id_piece
group by num_piece,description
order by profit desc;

--14. Créer une procedure stockée pour permettre à un utilisateur de filtrer les voitures recherchées en fonction des critères suivants: 
--année, puissance et lettre initiale de la marque.

create procedure getVoitureParAnneeChevauxMarque @annee varchar(4), @chevaux int, @marque varchar(50)
 as
 select modele, marque, annee, chevaux_vapeur from VoitureVente
 where CONVERT(date, annee) >=CONVERT(date, @annee) and chevaux_vapeur >= @chevaux and  marque  like @marque +'%'; 
 go


 drop procedure getVoitureParAnneeChevauxMarque


 exec getVoitureParAnneeChevauxMarque @annee = '1995', @chevaux = 300, @marque='F'


 --15.Créer une procedure stockee qui permet à l'utilisateur de mettre à jour les rangees d'une table qui répond aux critères de la province 
 --et de définir sa province et sa ville comme l'utilisateur le souhaite.

 create procedure updateClient @province varchar(50), @remplacant varchar(50),@remplacant1 varchar(50)
 as 

 update Client 
 set province = @remplacant, ville = @remplacant1
 where province like '%'+@province+'%';
 go


 drop procedure updateClient;
 exec updateClient @province='geo', @remplacant = 'Quebec',@remplacant1 = 'Gatineau';

 select * from client where ville = 'gatineau'


 --16.Creation des index appropriés sur la table facture achat

 create nonclustered index idx_voiture_facture_achat 
 on dbo.factureAchat(id_voiture)

 create nonclustered index idx_vendeur_facture_achat
 on dbo.FactureAchat(id_vendeur)


  --creation des index appropriés sur la table facture vente
create nonclustered index idx_client_Facture_Vente
on dbo.FactureVente(id_client)
create nonclustered index idx_voiture_factureVente
on dbo.FactureVente(id_voiture)

--17. Création de vue sur la requete Numero 1 section 2
create view Voiture_plus_rentables as
SELECT top 10 (t2.prix-t3.prix) as profit , marque, modele FROM VoitureVente as t1
join FactureVente as t2 on t2.id_voiture = t1.id_voiture
join FactureAchat as t3 on t3.id_voiture = t1.id_voiture
ORDER BY profit desc

select * from Voiture_plus_rentables

--création des vues sur la requete Numero 4 section 2
create view voitures_marque_Ford_moins_200_chevaux_et_4_portes as 
SELECT * FROM VoitureVente
WHERE marque ='ford' And chevaux_vapeur >=200 
  And numero_portes >=4 
  And ((sieges_en_cuir = 1 and demarrage_a_distance = 1) or (demarrage_a_distance=1 and toit_ouvrant =1) or (sieges_en_cuir=1 and toit_ouvrant=1));

  select * from voitures_marque_Ford_moins_200_chevaux_et_4_portes


