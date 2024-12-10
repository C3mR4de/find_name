.section .rodata
people_list:
    .asciz "Новиков Иван Петрович\nПетров Илья Васильевич\nСидоров Сергей Васильевич\nФёдоров Иван Алексеевич\n"
name:
    .asciz "Иван"
    .set name_length, . - name
newline:
    .byte '\n'
space:
    .byte ' '
skip_line:
    .asciz " .........."
    .set skip_line_length, . - name - 1

.section .bss
count:
    .quad 0

.macro put_string str, size
    # Адрес начала строки, которую будем выводить: \str
    movq $1, %rax       # Системный вызов write
    movq $1, %rdi       # Дескриптор stdout
    movq $\str, %rsi    # Начало строки   
    movq $\size, %rdx   # Длина строки
    syscall
.endm

.macro put_char char
    # Символ, который будем выводить: \char
    movq $1, %rax            # Системный вызов write
    movq $1, %rdi            # Дескриптор stdout
    lea \char(%rip), %rsi    # Адрес символа
    movq $1, %rdx            # Длина данных 1 байт (один символ)
    syscall                  # Вызов системного вызова
.endm

.macro put_uint reg
    # Регистр общего назначения с числом: \reg
    # Стековый регистр будет использоваться для построения строки числа
    subq $32, %rsp         # Резервируем место на стеке для временного буфера
    movq %rsp, %rsi        # Указатель на конец буфера (для построения строки)

    movq \reg, %rax        # Копируем значение в %rax для вычислений
    xorq %rcx, %rcx        # %rcx = счётчик символов

1:  xorq %rdx, %rdx        # %rdx = 0, используется для деления
    movq $10, %rbx         # Делитель (10)
    divq %rbx              # %rax /= 10, остаток в %rdx (цифра числа)

    addb $'0', %dl         # Преобразуем остаток (0-9) в ASCII-символ
    decq %rsi              # Сдвигаем указатель в буфере назад
    movb %dl, (%rsi)       # Записываем символ в буфер
    incq %rcx              # Увеличиваем счётчик символов

    testq %rax, %rax       # Проверяем, есть ли ещё цифры
    jnz 1b                 # Если %rax != 0, продолжаем

    # Вывод результата
    movq $1, %rax          # Системный вызов write
    movq $1, %rdi          # Дескриптор stdout
    movq %rsi, %rsi        # Адрес строки
    movq %rcx, %rdx        # Длина строки
    syscall                # Вызов системного вызова

    addq $32, %rsp         # Восстанавливаем стек
.endm

.globl _start
.section .text
_start:
    xorq %rdi, %rdi     # Обнуляем %rdi - индекс символа в строке people_list
    xorq %r10, %r10     # Обнуляем %r10 - счётчик количества совпавших имён

loop_check_end:    
    # Смотрим текущий символ в строке people_list
    movb people_list(%rdi), %al
    
    # Проверяем на конец строки
    cmpb $0, %al
    je print_result
    
    # Проверяем на пробел 
    cmpb $' ', %al
    je skip_char
    
    # Проверяем на перевод на новую строку
    cmpb $'\n', %al
    je skip_char
    
    callq compare_strings  # Сравниваем строки на равенство

    # Если строки совпали, увеличиваем счётчик на единицу
    testb %al, %al
    je increment_count

# Пропуск символа
skip_char:
    incq %rdi
    jmp loop_check_end

# Инкремент счётчика
increment_count:
    incq %r10
    jmp loop_check_end

# Сравнение строк
compare_strings:
    xorq %rsi, %rsi     # Обнуляем %rsi - индекс строки name

compare_loop:
    movb name(%rsi), %al        # Получаем очередной символ в строке name
    movb people_list(%rdi), %dl # Получаем очередной символ в строке people_list
    
    cmpb $0, %al    # Конец строки name?
    je compare_end
    
    cmpb $' ', %dl  # А пробел ли на месте rdi?
    je compare_end
    
    cmpb %dl, %al   # А равны ли символы в строках?
    jne compare_end
    
    incq %rsi           # Если равны, инкрементируем индексы
    incq %rdi           # И этот тоже
    jmp compare_loop    # Сравниваем дальше

compare_end:
    cmpb $0, %al  # Проверяем, а точно ли мы дошли до конца строки name?
    setne %al     # Если да, устанавливаем %al в 0
    cmpb $' ', %dl
    sete %ah
    andb %al, %dl
    retq

print_result:
    put_string name, name_length  
    put_string skip_line, skip_line_length
    put_char space
    put_uint %r10 
    put_char newline
    
    jmp exit

exit:
    movq $60, %rax
    xorq %rdi, %rdi
    syscall
