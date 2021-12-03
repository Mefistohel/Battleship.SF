
from random import randint

class BoardException(Exception):
    pass

class BoardOutException(BoardException):
    def __str__(self):
        return "Вы не попали в доску"

class BoardUsedException(BoardException):
    def __str__(self):
        return "Вы уже стреляли в эту клетку"

class BoardWrongShipException(BoardException):
    pass


class Dot:
    def __init__(self, x, y):
        self.x = x
        self.y = y
    
    def __eq__(self, other):
        return self.x == other.x and self.y == other.y
    
    def __repr__(self):
        return f"Dot({self.x}, {self.y})"


class Ship:
    def __init__(self, bow, length, o):
        self.bow = bow
        self.length = length
        self.o = o
        self.hp = length

    @property
    def dots(self):
        ship_dots = []
        for i in range(self.length):
            cur_x = self.bow.x 
            cur_y = self.bow.y
            
            if self.o == 0:
                cur_x += i
            
            elif self.o == 1:
                cur_y += i
            
            ship_dots.append(Dot(cur_x, cur_y))
        
        return ship_dots


    def shooten(self, shot):
        return shot in self.dots

class Board:
    def __init__(self, hid = None, size = 6):
        self.hid = hid
        self.size = size
        self.busy = []
        self.ships = []
        self.field = [ [" "]*size for _ in range(size) ]
        self.count = 0
    
    def __str__(self):
        res = ""
        res += "  | 1 | 2 | 3 | 4 | 5 | 6 |"
        for i, row in enumerate(self.field):
            res += f"\n{i+1} | " + " | ".join(row) + " |"
        
        if self.hid:
            res = res.replace("*", " ")
        return res

    def out(self, a):
        return not((0<= a.x < self.size) and (0<= a.y < self.size))
    
    def add_ship(self, ship):
        for a in ship.dots:
            if self.out(a) or a in self.busy:
                raise BoardWrongShipException()
        for a in ship.dots:
            self.field[a.x][a.y] = "*"
            self.busy.append(a)

        self.ships.append(ship)
        self.contour(ship)

    def contour(self, ship, verb = False):
        near = [
            (-1, -1), (-1, 0), (-1, 1),
            (0, -1), (0, 0), (0 , 1),
            (1, -1), (1, 0), (1, 1)
        ]
        for a in ship.dots:
            for ax, ay in near:
                cur = Dot(a.x + ax, a.y + ay)
                if not(self.out(cur)) and cur not in self.busy:
                    if verb:
                        self.field[cur.x][cur.y] = "."
                    self.busy.append(cur)
    
    def shot(self, a):
        if self.out(a):
            raise BoardOutException()
        
        if a in self.busy:
            raise BoardUsedException()
        
        self.busy.append(a)
        
        for ship in self.ships:
            if a in ship.dots:
                ship.hp -= 1
                self.field[a.x][a.y] = "X"
                if ship.hp == 0:
                    self.count += 1
                    self.contour(ship, verb = True)
                    print("Убил!")
                    return False
                else:
                    print("Ранил!")
                    return True
        
        self.field[a.x][a.y] = "."
        print("Мимо!")
        return False
    
    def begin(self):
        self.busy = []

class Player:
    def __init__(self, board, enemyboard):
        self.board = board
        self.enemyboard = enemyboard
    
    def ask(self):
        raise NotImplementedError()
    
    def move(self):
        while True:
            try:
                target = self.ask()
                repeat = self.enemyboard.shot(target)
                return repeat
            except BoardException as e:
                print(e)

class AI(Player):
    def ask(self):
        a = Dot(randint(0,5), randint(0, 5))
        print(f"Ход компьютера: {a.x+1} {a.y+1}")
        return a

class User(Player):
    def ask(self):
        while True:
            cords = input("Ваш ход: ").split()
            
            if len(cords) != 2:
                print(" Введите 2 координаты ")
                continue
            
            x, y = cords
            
            if not(x.isdigit()) or not(y.isdigit()):
                print(" Введите числа ")
                continue
            
            x, y = int(x), int(y)
            
            return Dot(x-1, y-1)

class Game:
    def try_board(self):
        lens = [3, 2, 2, 1, 1, 1, 1]
        board = Board(size = self.size)
        attempts = 0
        for length in lens:
            while True:
                attempts += 1
                if attempts > 2000:
                    return None
                ship = Ship(Dot(randint(0, self.size), randint(0, self.size)), length, randint(0,1))
                try:
                    board.add_ship(ship)
                    break
                except BoardWrongShipException:
                    pass
        board.begin()
        return board
    
    def random_board(self):
        board = None
        while board is None:
            board = self.try_board()
        return board

    def __init__(self, size = 6):
        self.size = size
        pl = self.random_board()
        co = self.random_board()
        co.hid = True
        
        self.ai = AI(co, pl)
        self.us = User(pl, co)
    
    def greet(self):
        print("-------------------")
        print("  Приветсвуем вас  ")
        print("      в игре       ")
        print("    морской бой    ")
        print("-------------------")
        print(" формат ввода: x y ")
        print(" x - номер строки  ")
        print(" y - номер столбца ")
   
    def loop(self):
        num = 0
        while True:
            print("-"*20)
            print("Доска пользователя:")
            print(self.us.board)
            print("-"*20)
            print("Доска компьютера:")
            print(self.ai.board)
            print("-"*20)
            if num % 2 == 0:
                print("Ходит пользователь!")
                repeat = self.us.move()
            else:
                print("Ходит компьютер!")
                repeat = self.ai.move()
            if repeat:
                num -= 1
            
            if self.ai.board.count == 7:
                print("-"*20)
                print("Пользователь выиграл!")
                break
            
            if self.us.board.count == 7:
                print("-"*20)
                print("Компьютер выиграл!")
                break
            num += 1
    
    def start(self):
        self.greet()
        self.loop()
            
            
g = Game()
g.start()
