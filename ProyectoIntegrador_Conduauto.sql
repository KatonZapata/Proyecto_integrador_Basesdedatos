--creacion base de datos y uso de la base creada
create database Conduautos
use Conduautos
--creaion de tablas con los constraint
create table Estudante(
idEstudiante int,
constraint PK_idEstudiante primary key(idEstudiante),
nombreEst	nvarchar(20) not null,
apellidoEst nvarchar(40) not null,
telefEs		numeric(10)  not null,
dirEst		nvarchar(40) not null,
emailEst	nvarchar(40) not null,
constraint UQ_emailEst unique (emailEst),
edadEst		numeric(2)not null,
constraint CK_edadEst check (edadEst >=16)
);

create table Profesor(
idProf		int,
constraint PK_idProf primary key(idProf),
nombreProf	nvarchar(20)not null,
apellidoPro nvarchar(40)not null,
telProf		numeric (10)not null
);

create table Vehiculo(
placa	nvarchar(6),
constraint PK_placa primary key(placa),
marca	nvarchar(10)not null,
modelo	numeric (4)not null,
color	nvarchar(20)not null,
idChasis nvarchar(30)not null,
constraint UQ_idChasis unique(idChasis)
);

create table AgendaClase(
codClase		int identity,
constraint PK_codClase primary Key (codClase),
fechaClase		datetime not null,
duracionClase	time not null,
constraint CK_duracionClase check(duracionClase>='02:00:00' and duracionClase<='04:00:00'),
estado			nvarchar(10) not null,
idEst_FK		int not null,
constraint FK_idEst_FK foreign key (idEst_FK) references Estudante(idEstudiante)on Delete cascade on update cascade,
idProf_FK		int not null,
constraint FK_idProf_FK foreign key (idProf_FK) references Profesor(idProf)on delete cascade on update cascade
);

create table VehiculoProfesor(
codVehiProf		int identity,
constraint PK_codVehiProf primary key(codVehiProf),
idProfFK		int not null,
constraint FK_idProfFK foreign key (idProfFK) references Profesor(idProf)on delete cascade on update cascade,
placaFK			nvarchar(6)not null,
constraint FK_placaFK foreign key (placaFK) references Vehiculo(placa)on delete cascade on update cascade
);

create table Categoria(
codCategoria	int identity,
constraint PK_codCategoria primary key(codCategoria),
nombreCat		nvarchar(20)not null,
tipoCat			nvarchar(10)not null,
placaVehiFK		nvarchar(6)not null,
constraint FK_placaVehiFK foreign key (placaVehiFK) references Vehiculo(placa)on delete cascade on update cascade
);

--insersion de datos

bulk insert Estudante
from 'C:\Users\diani\OneDrive\Escritorio\cesde\1 semestre\Bases de datos\talleres y ejercicios\Proyecto integrador\bulk_proyecto_integrador.txt'
with (firstrow =2);

bulk insert Profesor
from 'C:\Users\diani\OneDrive\Escritorio\cesde\1 semestre\Bases de datos\talleres y ejercicios\Proyecto integrador\bulk_proyecto_integrador1.txt'
with (firstrow =2);

bulk insert Vehiculo
from 'C:\Users\diani\OneDrive\Escritorio\cesde\1 semestre\Bases de datos\talleres y ejercicios\Proyecto integrador\bulk_proyecto_integrador2.txt'
with (firstrow =2);

bulk insert AgendaClase
from 'C:\Users\diani\OneDrive\Escritorio\cesde\1 semestre\Bases de datos\talleres y ejercicios\Proyecto integrador\bulk_proyecto_integrador3.txt'
with (firstrow =2);

bulk insert VehiculoProfesor
from 'C:\Users\diani\OneDrive\Escritorio\cesde\1 semestre\Bases de datos\talleres y ejercicios\Proyecto integrador\bulk_proyecto_integrador4.txt'
with (firstrow =2);

bulk insert Categoria
from 'C:\Users\diani\OneDrive\Escritorio\cesde\1 semestre\Bases de datos\talleres y ejercicios\Proyecto integrador\bulk_proyecto_integrador5.txt'
with (firstrow =2);

--creando procedimientos almacenados--
create proc P_agendamiento
	@idEstFK	int,
	@idProfFK	int,
	@fechaClase	datetime,
	@duracion	time
as
	insert into AgendaClase(idEst_FK,idProf_FK,fechaClase,duracionClase,estado)
	values(@idEstFK,@idProfFK,@fechaClase,@duracion,'No Asignado');

create trigger T_Agendamiento
on AgendaClase
after insert
as
declare 
	@codCla		int,
	@idEstFk	int,
	@idProfFk	int

	select @codCla=codClase, @idEstFk=idEst_FK,@idProfFk=idProf_FK from inserted;

	update AgendaClase
	set estado='Agendado'
	where codClase=@codCla;

-- crear un procedimiento para consultar las clases que tiene un profesor en una fecha determinada,
--en caso de no tenerlas enviar un mensaje que el profesor no tiene clases asignadas--

create or alter procedure P_clasesProfesor
	@idProfesor int,
	@fechaClase datetime
as
	if exists(select codClase,fechaClase,duracionClase,estado from AgendaClase	where idProf_FK=@idProfesor and fechaClase=@fechaClase)
	select codClase,fechaClase,duracionClase,estado
	from AgendaClase
	where idProf_FK=@idProfesor and fechaClase=@fechaClase;

	else
		select 'El profesor no tiene clases asignadas en la fecha seleccionada' as MensajeAlerta;

--crear un pocedimiento para que un estudiante consulte las clases pacticas que tiene agendadas,

create or alter proc P_clasesEstudiante
	@idEstFK int,
	@estado	varchar(10)
as
	if exists(select ag.codClase,ag.fechaClase,ag.duracionClase,ag.estado,CONCAT(p.nombreProf,' ',p.apellidoPro)as 'Nombre profesor' from AgendaClase as ag 
	inner join Profesor as p on ag.idProf_FK=p.idProf where ag.idEst_FK=@idEstFK and estado=@estado)
	select ag.codClase,ag.fechaClase,ag.duracionClase,ag.estado,CONCAT(p.nombreProf,' ',p.apellidoPro)as 'Nombre profesor' from AgendaClase as ag 
	inner join Profesor as p on ag.idProf_FK=p.idProf where ag.idEst_FK=@idEstFK and estado=@estado

	else 
		select 'El estuduante no tiene clases Agendadas' as MensajeAlerta;

--