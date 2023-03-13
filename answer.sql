----------------------------------------------------------------------------------------------------------
------------------------------------------------- ЗАДАЧА №1 ----------------------------------------------
----------------------------------------------------------------------------------------------------------

-- Ошибка = Дата начала Счета < Даты начала Договора
-- ИЛИ Дата окончания Счета >= Даты окончания договора + 1 день (предполагается действие договора "по" дату, т.е. включительно)
-- ИЛИ Дата окончания Счета >= Даты окончания договора, когда Дата окончания Счета = бесконечность И Дата окончания договора указана
SELECT *
FROM Test.Accounts as A
         JOIN Test.Contracts as C ON C.[Id] = A.[Contract_Id]
WHERE A.[DateTimeFrom] < C.[DateFrom]
   OR A.[DateTimeTo] >= DATEADD(day, 1, C.[DateTo])
   OR (A.[DateTimeTo] IS NULL AND C.[DateTo] IS NOT NULL)

----------------------------------------------------------------------------------------------------------
------------------------------------------------- ЗАДАЧА №2 ----------------------------------------------
----------------------------------------------------------------------------------------------------------

DECLARE @WithOutDepart_Id Int = 2;

WITH Children as
         (SELECT D.[Id]
          FROM [Test].[Departs] D
          WHERE D.[Id] = @WithOutDepart_Id

          UNION ALL

          SELECT D.[Id]
          FROM [Test].[Departs] D
                   JOIN Children C ON D.[Parent_Id] = C.[Id])

SELECT D.*
FROM Test.Departs D
WHERE NOT EXISTS(SELECT * FROM Children C WHERE D.[Id] = C.[Id]);

-- В случае необходимости частого получения поддеревьев как в данном запросе, должно быть эффективнее использовать hierarchyid с индексом

----------------------------------------------------------------------------------------------------------
------------------------------------------------- ЗАДАЧА №3 ----------------------------------------------
----------------------------------------------------------------------------------------------------------

DECLARE
    @DateFrom Date = '20150101'
DECLARE
    @DateTo   Date = DATEADD(Day, 7, @DateFrom),
    @BaseCurrency_Id Int = 1

SELECT T.[Client_Id], T.[Currency_Id], SUM(T.[DayBalance] * ISNULL(T.[RateDivVol], 1)) AS Balance
FROM (SELECT O.[Client_Id],
             O.[Currency_Id],
             O.[Date],
             SUM([Value])              as DayBalance,
             (SELECT TOP 1 CAST(CR.[Rate] as decimal(32, 28)) / CR.[Volume]
              FROM TEST.CurrenciesRates CR
              WHERE CR.[Date] <= O.[Date]
                AND CR.[Currency_Id] = O.[Currency_Id]
                AND CR.[BaseCurrency_Id] = @BaseCurrency_Id
              ORDER BY CR.[Date] DESC) as RateDivVol
      FROM [Test].[Operations] O
      WHERE O.[Date] >= @DateFrom
        AND O.[Date] < @DateTo
      GROUP BY O.[Client_Id], O.[Currency_Id], O.[Date]) T
GROUP BY [Client_Id], [Currency_Id]
ORDER BY [Client_Id], [Currency_Id]

-- Для оптимизации поиска по Operations может быть выбран индекс columnstore, при поиске по дате будет использован Index Scan
--CREATE COLUMNSTORE INDEX IX_SalesOrderDetail_ProductIDOrderQty_ColumnStore
--ON [Test].[Operations] ([Date], [Client_Id], [Currency_Id], [Value]);

-- Подойдет покрывающий индекс по дате, включающий остальные получаемые [Client_Id], [Currency_Id] и [Value]
-- Будет использован Index Seek, что лучше по времени выполнения запроса
-- Но данный индекс по сравнению с columnstore более тяжелый в поддержке и может замедлить добавление/обновление данных
CREATE NONCLUSTERED INDEX IX_Operations_Date
   ON [Test].[Operations] ([Date]) INCLUDE ([Client_Id], [Currency_Id], [Value]);
-- Поэтому, если позволяет остальная БЛ приложения и схема БД, можно сделать кластерный индекс по [Date] вместо [Id]