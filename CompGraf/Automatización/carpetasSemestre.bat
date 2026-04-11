set /p semestre = Ingrese el semestre a cursar:

mkdir %semestre%
cd %semestre%

set /p materias = Cuantas materias va a cursar?

set i = 1

:loop
if %i% GTR %num% goto fin

set /p materia = Nombre de la materia %i%:

mkdir "%materia%"

set /a i = %i% + 1
goto loop

:fin

pause