
----------------------------------------------------------------------------------------------------------
------------------------------------------------- ������ �1 ----------------------------------------------
----------------------------------------------------------------------------------------------------------
/*
  �������� ������, ������� ������ ������ "������" � ������� �������.
  ��� "�������" ��������������� ��������, ����� ���� ��������� (����������), � �������, � ������ �������� �������� ����, �� ��������� (�� ����������).
*/

--------------------------------------------------------------------------------------
-- ��������� ������                                                                 --
--------------------------------------------------------------------------------------
  EXEC('CREATE SCHEMA [Test]')
  GO

  -- ��������
  CREATE TABLE [Test].[Contracts]
  (
    [Id]        Int           NOT NULL  IDENTITY(1,1),
    [DocNo]     NVarChar(50)  NOT NULL,
    [DateFrom]  Date          NOT NULL, --  ����, ����� ������� ����� �����������
    [DateTo]    Date              NULL, --  ����, ����� ������� ���������� ����������� (��������� ���� �������� ��������); NULL = �������������
    -- ... � ��� �����-�� ����
    PRIMARY KEY CLUSTERED([Id])
  )
  GO

  -- �����
  CREATE TABLE [Test].[Accounts]
  (
    [Id]            Int           NOT NULL  IDENTITY(1,1),
    [Contract_Id]   Int           NOT NULL, -- �������, � ������ �������� ���� ��������
    [Number]        NVarChar(50)  NOT NULL, -- ����� �����
    [DateTimeFrom]  DateTime      NOT NULL, -- ������ ������� (����+�����!), ����� ���� ����� �����������
    [DateTimeTo]    DateTime          NULL, -- ������ ������� (����+�����!), ����� ���� ��������� �����������
    -- ... � ��� �����-�� ����
    PRIMARY KEY CLUSTERED([Id]),
    FOREIGN KEY ([Contract_Id]) REFERENCES [Test].[Contracts] ([Id])
  )
  GO

----------------------------------------------------------------------------------------------------------
------------------------------------------------- ������ �2 ----------------------------------------------
----------------------------------------------------------------------------------------------------------
/*
��� �������� � ������������� ���������� �������������. ���� ������ ��� �������������, �������� �� ������� ��������� � ���������, � ����� �������� ���� ��� ����� � ������.

DECLARE
  @WithOutDepart_Id Int = ...

-- ������ ��� �������������, ����� ������������� @WithOutDepart_Id � ����� ���� ��� ����� � ������
...
SELECT D.*
FROM [Test].[Departs] D
...

*/

--------------------------------------------------------------------------------------
-- ��������� ������                                                                 --
--------------------------------------------------------------------------------------
  EXEC('CREATE SCHEMA [Test]')
  GO

  CREATE TABLE [Test].[Departs]
  (
	[Id]        Int           NOT NULL IDENTITY(1,1),
	[Parent_Id] Int               NULL REFERENCES [Departs] ([Id]),
	[Name]      NVarChar(100) NOT NULL,
	PRIMARY KEY CLUSTERED([Id])
  )
  GO
  -- � ������ ������������� ������� ��������� ����������� �������� ����� ����������� ������������ hierarchyid � ��������
  -- ���� �� ����� �������, ��� ������ �������  ���������� ������� �� Parent_Id �� ������ �������������� �������
-- ���������� ����������� �������, ���� �������� ������.

----------------------------------------------------------------------------------------------------------
------------------------------------------------- ������ �3 ----------------------------------------------
----------------------------------------------------------------------------------------------------------
/*
�������� ������, ������� ������ ������� �� �������� � ��������� ����:
-- Client_Id    -- ������
-- Currency_Id  -- ������
-- Balance      -- ��������� ������� ������� � ������� ������ = ����� ���� ��������, � ������� Date >= @DateFrom � Date < @DateTo
������� ������ ������:
-- ORDER BY Client_Id, Currency_Id

��� ���� �������� ���������:
  @BaseCurrency_Id     - ������������� ������� ������, � ������� ���� �������� ����� Balance;
  @DateFrom, @DateTo   - ������ �� ������� ���� ��������� ������ �������

��� ��������� ������� ������������, ��� � ������� [Test].[CurrenciesRates] ���� ����� ��� [BaseCurrency_Id] = @BaseCurrency_Id
(�.�. �� ���� ��������� ������ �� �����-������)

�������: � ������� Operations ����� ����� ������. @DateFrom � @DateTo, ��� �������, ��������� ������ (�� ����� 1 ������ ��� ����� ������� ������ � Operations �� ����� 3-� ���)
���������� ������� ������(�) ��� ������� �������(��).

����������������/��������� ��� �����. ����� ���� ��������. ������ "��"/"���"?
*/

----------------------------------------------------
-- ������ �������� ����������:
-----------------------------------------------------
SET NOCOUNT ON
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

DECLARE
  @DateFrom         Date    = '20150101'
DECLARE
  @DateTo           Date    = DATEADD(Day, 7, @DateFrom),
  @BaseCurrency_Id  Int     = 1

--------------------------------------------------------------------------------------
-- ��������� ������                                                                 --
--------------------------------------------------------------------------------------
  EXEC('CREATE SCHEMA [Test]')
  GO

  CREATE TABLE [Test].[Clients]
  (
    [Id]        Int                                   NOT NULL  IDENTITY(1,1),
    [Name]      NVarChar(128)                         NOT NULL,
    -- ... � ��� �����-�� ����
    PRIMARY KEY CLUSTERED([Id])
  )
  GO

  CREATE TABLE [Test].[Currencies]
  (
    [Id]   Int                                   NOT NULL,
    [Code] Char(3) COLLATE Cyrillic_General_BIN  NOT NULL,
    [Name] NVarChar(128)                         NOT NULL,
    PRIMARY KEY CLUSTERED([Id])
  )
  GO

  CREATE TABLE [Test].[CurrenciesRates]
  (
    [Currency_Id]       Int           NOT NULL, -- ������, ���� ������� ������
    [BaseCurrency_Id]   Int           NOT NULL, -- ������� ������; ��� ���� USD/RUB � ���� �aseCurrency_Id ����� ������ �� RUB; � ���� Currency_Id - ������ �� USD; � ���� Rate = ���� = 60; �.�. 60 RUB = 1 USD
    [Date]              Date          NOT NULL, -- ���� �����
    [Rate]              Numeric(32,8) NOT NULL, -- ���������� ���� 
    [Volume]            Numeric(18,8) NOT NULL, -- �� ����������; ��������, �� 10 000 ����������� ������ ���� 39.4419 ������; Rate = 39.4419; Volume = 10 000;
    PRIMARY KEY CLUSTERED([Currency_Id], [BaseCurrency_Id], [Date]),
    FOREIGN KEY ([Currency_Id]) REFERENCES [Test].[Currencies] ([Id]),
    FOREIGN KEY ([BaseCurrency_Id]) REFERENCES [Test].[Currencies] ([Id])
  )
  GO
-- ����� �������� ����� Sb � @BaseCurrency_Id, ���� � ��� ���� ����� Sc � ������ Currency_Id,
-- �� ���� ����� �� ������������ ���� ����� ��������� �� ���� ������ (���� ���� �� �� ������ ����),
-- ��� [BaseCurrency_Id] = @BaseCurrency_Id � [Currency_Id] = @Currency_Id � [Date] <= @Date,
-- �������� �� Rate � ��������� �� Volume
-- �.�. Sb = Sc * Rate / Volume �� ��������� ����

  CREATE TABLE [Test].[Operations]
  (
    [Id]                Int           NOT NULL IDENTITY(1,1),
    [Date]              Date          NOT NULL,               -- ���� ��������
    [Client_Id]         Int           NOT NULL,               -- ������, �� �������� �������� ������
    [Value]             Numeric(32,8) NOT NULL,               -- �����, �� ������� �������� ������
    [Currency_Id]       Int           NOT NULL,               -- ������ ��������
    [DocNo]             NVarChar(32)      NULL,
    -- ... � ��� �����-�� ����
    PRIMARY KEY CLUSTERED([Id]),
    FOREIGN KEY ([Currency_Id]) REFERENCES [Test].[Currencies] ([Id]),
    FOREIGN KEY ([Client_Id]) REFERENCES [Test].[Clients] ([Id])
  )
  GO

----------------------------------------------------
-- ��������� ������
-----------------------------------------------------
INSERT INTO [Test].[Clients] ([Name])
SELECT
  [Name]    = CAST(O1.[object_id] AS NVarChar(128)) + ' - ' + CAST(O2.[object_id] AS NVarChar(128))
FROM
(
  SELECT TOP (100)
    O.[object_id]
  FROM sys.all_objects O
) O1
CROSS APPLY
(
  SELECT TOP (20)
    O.[object_id]
  FROM sys.all_objects O
) O2
GO

INSERT INTO [Test].[Currencies]
VALUES
  (1, 'RUB', 'Ruble'),
  (2, 'USD', 'Dollar USA'),
  (3, 'EUR', 'Euro'),
  (4, 'JPY', 'Ena'),
  (5, 'BYR', 'Belorussian ruble')
GO

DECLARE @DateStart Date = '20130101'
INSERT INTO [Test].[CurrenciesRates]
SELECT
  [Currency_Id]     = C.[Id],
  [BaseCurrency_Id] = 1,
  [Date]            = DATEADD(Day, I.[RowNumber], @DateStart),
  [Rate]            = CASE C.[Code]
                        WHEN 'USD' THEN 60 - 10 + RAND( CAST(CAST(RIGHT(NewId(), 4) AS Binary(4)) AS Int) ) * 20
                        WHEN 'EUR' THEN 70 - 10 + RAND( CAST(CAST(RIGHT(NewId(), 4) AS Binary(4)) AS Int) ) * 20
                        WHEN 'JPY' THEN 40 - 10 + RAND( CAST(CAST(RIGHT(NewId(), 4) AS Binary(4)) AS Int) ) * 20
                        WHEN 'BYR' THEN 35 - 7 + RAND( CAST(CAST(RIGHT(NewId(), 4) AS Binary(4)) AS Int) ) * 15
                      END,
  [Volume]          = CASE
                        WHEN C.[Code] = 'BYR' THEN 10000
                        WHEN C.[Code] = 'JPY' THEN 100
                        ELSE 1
                      END
FROM [Test].[Currencies] C
CROSS APPLY
(
  SELECT TOP (365*3)
    [RowNumber]     = ROW_NUMBER() OVER (ORDER BY O1.[object_id], O2.[object_id])
  FROM
  (
    SELECT TOP (100)
      O.[object_id]
    FROM sys.all_objects O
  ) O1
  CROSS APPLY
  (
    SELECT TOP (50)
      O.[object_id]
    FROM sys.all_objects O
  ) O2
) I
WHERE C.[Id] > 1 -- ����� �����
  AND I.[RowNumber] % 10 > 2 -- ����� ���� ������� � ������
GO

-- �� 3 ���� 2013, 2014, 2015
-- ������, ��� ����� ���������� ����� ����� �� 1 ����!
DECLARE
  @DateStart  Date        = '20130101',
  @N          Int         = 12 * 3,
  @DebugTime  DateTime    = GETDATE()

WHILE @N > 0 BEGIN

  INSERT INTO [Test].[Operations] ([Date], [Client_Id], [Value], [Currency_Id], [DocNo])
  SELECT
    [Date]        = DATEADD(Day, I.[RowNumber], @DateStart),
    [Client_Id]   = C.[Id],
    [Value]       = RAND( CAST(CAST(RIGHT(NewId(), 4) AS Binary(4)) AS Int) ) * 1000 - 500,
    [Currency_Id] = CR.[Id],
    [DocNo]       = CAST(C.[Id] AS NVarChar(20)) + N'/' + CAST(CR.[Id] AS NVarChar(20)) + N'/' + CAST(I.[RowNumber] AS NVarChar(20)) + N'-' + CAST(I2.[RowIndex] AS NVarChar(20))
  FROM [Test].[Clients]          C
  CROSS JOIN [Test].[Currencies] CR
  CROSS APPLY
  (
    SELECT TOP (30)
      [RowNumber]     = ROW_NUMBER() OVER (ORDER BY O.[object_id])
    FROM sys.all_objects O
  ) I
  CROSS APPLY
  (
    SELECT TOP (20)
      [RowIndex]      = ROW_NUMBER() OVER (ORDER BY O.[object_id])
    FROM sys.all_objects O
  ) I2

  SET @DateStart = DATEADD(Month, 1, @DateStart)
  SET @N -= 1

END

SELECT [RUN_TIME] = CONVERT(VarChar(20), GETDATE() - @DebugTime, 114)
GO

