SET @program = 'Age of Empires II Definitve Edition';
SET @gpu_base = (SELECT perfomance FROM gpu WHERE serie LIKE CONCAT('%', (SELECT rgpu FROM program WHERE name = @program), '%') LIMIT 1);
SET @cpu_base = (SELECT performances FROM cpu WHERE name LIKE CONCAT('%', (SELECT rcpu FROM program WHERE name = @program), '%') ORDER BY performances LIMIT 1);
SET @ram = (SELECT rram FROM program WHERE name = @program);
-- SSD en GB
SET @ssd = (SELECT rstorage FROM program WHERE name = @program);
-- HDD en TB
SET @hdd = (SELECT rstorage FROM program WHERE name = @program);

SELECT q3.Cpu AS CPU, q3.Cooler, q3.Motherboard,q3.Ram AS RAM, q2.Gpu AS GPU, q2.Power AS Power_Supply,
q1.CASE_ as Case_, q4.Ssd AS SSD, q5.Hdd AS HDD, 
q1.Price + q2.Price + q3.Price + q4.Price + q5.Price AS Price

FROM (SELECT DISTINCT C.name AS CASE_, C.width AS width, C.height AS height,
C.depth AS depth, C.price AS Price FROM mipc_test.case AS C
JOIN(SELECT DISTINCT width, depth, height, MIN(price) AS price FROM mipc_test.case
GROUP BY width, depth, height) q1
WHERE C.height = q1.height AND C.width = q1.width AND C.depth = q1.depth AND C.price = q1.price) q1

JOIN(SELECT DISTINCT GPU.name AS Gpu, POWER.name AS Power,GPU.length, POWER.width, 
POWER.height, POWER.depth, GPU.price + POWER.price AS Price
FROM gpu GPU
JOIN power POWER ON POWER.`6pin` >= GPU.`6pin`AND POWER.`8pin`>= GPU.`8pin`
JOIN(SELECT GPU.length, POWER.width, POWER.height, POWER.depth, MIN(GPU.price + POWER.price) AS Price
FROM gpu GPU
JOIN power POWER ON POWER.`6pin` >= GPU.`6pin`AND POWER.`8pin`>= GPU.`8pin`
WHERE GPU.perfomance >= @gpu_base
GROUP BY GPU.length, POWER.width, POWER.height, POWER.depth) q1
ON GPU.length = q1.length AND POWER.width  = q1.width AND  POWER.height = q1.height AND
POWER.depth = q1.depth AND GPU.price + POWER.price = q1.Price AND GPU.perfomance >= @gpu_base) q2
ON q2.length < q1.depth AND q2.width < q1.width AND q2.height < q1.height AND q2.depth < q1.depth

JOIN(SELECT q1.Cpu, q1.Cooler, q2.Motherboard, q2.Ram, q1.COOLER_Height, q2.MB_Height,
 q2.MB_Width, q1.Price + q2.Price AS Price
FROM
(SELECT DISTINCT CPU.name AS Cpu, CPU.socket AS Socket, COOLER.name AS Cooler, 
COOLER.height AS COOLER_Height, CPU.price + COOLER.price AS Price
FROM CPU cpu
JOIN cooler COOLER ON COOLER.sockets LIKE CONCAT('%',CPU.socket,'%')
JOIN
(SELECT CPU.socket,COOLER.height,MIN(CPU.price + COOLER.price) AS price
FROM cpu CPU
JOIN cooler COOLER ON COOLER.sockets LIKE CONCAT('%',CPU.socket,'%')
WHERE CPU.performances >= @cpu_base
GROUP BY CPU.socket,COOLER.height) q1
WHERE CPU.socket = q1.socket AND COOLER.height = q1.height AND CPU.price + COOLER.price = q1.price AND CPU.performances >= @cpu_base) q1

JOIN (SELECT DISTINCT MB.name AS Motherboard, MB.height AS MB_Height,
MB.width AS MB_Width, MB.socket AS Socket, RAM.name AS Ram, (MB.price + RAM.price) AS Price 
FROM motherboard MB
JOIN ram RAM ON  RAM.size >= @ram AND RAM.type LIKE CONCAT('%',MB.memorytype,'%') AND MB.ramslots >= RAM.sticks
JOIN (SELECT MB.socket,MB.width,MB.height, MIN(MB.price + RAM.price) AS price 
FROM motherboard MB 
JOIN ram RAM ON RAM.size >= @ram AND RAM.type LIKE CONCAT('%',MB.memorytype,'%') AND MB.ramslots >= RAM.sticks
GROUP BY MB.socket,MB.width,MB.height) q1
WHERE MB.socket = q1.socket AND MB.width = q1.width AND MB.height = q1.height 
AND (MB.price + RAM.price) = q1.price) q2 ON q1.Socket = q2.Socket) q3
ON q3.MB_Height < q1.height AND q3.MB_Width < q1.depth AND COOLER_Height < q1.height

JOIN (SELECT name AS Ssd, price AS Price 
FROM ssd 
WHERE size >= @ssd
ORDER BY price
LIMIT 1) q4

JOIN(SELECT name AS Hdd, price AS Price 
FROM hdd 
WHERE size*1000 >= @hdd
ORDER BY price
LIMIT 1) q5

ORDER BY Price
LIMIT 1000