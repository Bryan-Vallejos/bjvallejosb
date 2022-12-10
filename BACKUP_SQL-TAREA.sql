--Creacion de dispositivo de almacenamiento para la base de datos Adventureworks2019--
use master
go

EXEC sp_addumpdevice 'disk' , 'AdventureWorks2019BackupDevice' , 
'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup\AdventureWorks2019BackupDevice.bak';
GO

EXEC sp_dropdevice 'AdventureWorks2019BackupDevice', 'delfile' ;
go

--Crea una rutina que asigne nombres de backups únicos y haz que ejecute 4 backups sobre el dispositivo de backup creado en el punto anterior.
IF EXISTS (
  SELECT * 
    FROM INFORMATION_SCHEMA.ROUTINES 
   WHERE SPECIFIC_NAME = N'usp_CreateAWBackup' 
)
   DROP PROCEDURE usp_CreateAWBackup
GO

CREATE PROCEDURE usp_CreateAWBackup
AS  
	DECLARE @Backup_Name nvarchar(100)
	SET @Backup_Name = N'AdventureWorks2019 Full-Backup ' + FORMAT(GETDATE(), 'yyyyMMdd_hhmmss')
	BACKUP DATABASE AdventureWorks2019
	TO AdventureWorks2019BackupDevice
	WITH NOFORMAT, NOINIT, NAME = @Backup_Name;
GO

EXEC usp_CreateAWBackup
go
--Crea una rutina rutina que restuare uno de los backups con nombre AwExamenBDII basado en el número del archivo de backup.

if object_id('TempDB..#TableBackupHeader') is not null 
drop table #dbo.TableBackupHeader
go

IF EXISTS (
  SELECT * 
    FROM INFORMATION_SCHEMA.ROUTINES 
   WHERE SPECIFIC_NAME = N'usp_RestoreAWBackup' 
)
   DROP PROCEDURE usp_RestoreAWBackup
GO

CREATE PROCEDURE usp_RestoreAWBackup
AS

create table #TableBackupHeader
( 
    BackupName varchar(256),
    BackupDescription varchar(256),
    BackupType smallint,        
    ExpirationDate datetime,
    Compressed tinyint,
    Position smallint,
    DeviceType tinyint,        
    UserName varchar(128),
    ServerName varchar(128),
    DatabaseName varchar(128),
    DatabaseVersion int,        
    DatabaseCreationDate datetime,
    BackupSize numeric(25,0),
    FirstLSN numeric(25,0),
    LastLSN numeric(25,0),        
    CheckpointLSN numeric(25,0),
    DatabaseBackupLSN numeric(25,0),
    BackupStartDate datetime,
    BackupFinishDate datetime,        
    SortOrder smallint,
    CodePage smallint,
    UnicodeLocaleId int,
    UnicodeComparisonStyle int,        
    CompatibilityLevel tinyint,
    SoftwareVendorId int,
    SoftwareVersionMajor int,        
    SoftwareVersionMinor int,
    SoftwareVersionBuild int,
    MachineName varchar(128),
    Flags int,        
    BindingID uniqueidentifier,
    RecoveryForkID uniqueidentifier,
    Collation varchar(128),
    FamilyGUID uniqueidentifier,        
    HasBulkLoggedData INT,
    IsSnapshot INT,
    IsReadOnly INT,
    IsSingleUser INT,        
    HasBackupChecksums INT,
    IsDamaged INT,
    BeginsLogChain INT,
    HasIncompleteMetaData INT,        
    IsForceOffline INT,
    IsCopyOnly INT,
    FirstRecoveryForkID uniqueidentifier,
    ForkPointLSN numeric (25,0),        
    RecoveryModel varchar(128),
    DifferentialBaseLSN numeric (25,0),
    DifferentialBaseGUID uniqueidentifier,        
    BackupTypeDescription varchar(128),
    BackupSetGUID uniqueidentifier,
    CompressedBackupSize bigint,
	Containment INT,
	KeyAlgorithm varchar(500),
	EncryptorThumbprint varchar(500),
	EncryptorType varchar(500))

INSERT INTO #TableBackupHeader
EXEC('RESTORE HEADERONLY FROM AdventureWorks2019BackupDevice')
	
	DECLARE @File smallint
	SELECT @File = max(Position)
	FROM #TableBackupHeader
	--WHERE BackupName = 'AdventureWorks2019 Full-Backup '
	
	RESTORE DATABASE AwExamenBDII
	FROM AdventureWorks2019BackupDevice
	WITH FILE = @File,
		MOVE N'AdventureWorks2017' TO N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\AwExamenBDII.mdf',
		MOVE N'AdventureWorks2017_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\AwExamenBDII_log.ldf',
	NOUNLOAD, REPLACE, STATS = 10
GO

EXEC usp_RestoreAWBackup
go

RESTORE HEADERONLY FROM AdventureWorks2019BackupDevice
GO

RESTORE FILELISTONLY FROM AdventureWorks2019BackupDevice
GO

