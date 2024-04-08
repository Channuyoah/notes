## JS Prototype(原型链)

文档链接：https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Inheritance_and_the_prototype_chain

继承时JS只有一种结构：对象。每个对象都有一个私有属性指向另一个名为原型(prototype)的对象。原型对象也有自己的原型，层层向上直到一个对象的原型为null，null没有原型，作为原型链(prototype chain)的最后一环。因为可以改变原型链中的任何成员，甚至可以在运行时换出原型，因此JS中不存在静态分派的概念。

#### 静态分派：

```C++
/* 静态分派（Static Dispatch）是指在编译时确定调用哪个函数或方法的过程。
 * 在静态分派中，编译器可以根据变量的声明类型或者表达式的静态类型来决定调用哪个函数或方法。
 * 动态调度基于运行时信息（例如 vtable 指针和其他形式的运行时类型信息）
 */
class Base {
public:
    Base() {
        cout << "Base Create" << endl;
    }
    // 当这个foo未加virtual的时候调用的是Base的foo
    // 加上virtual则为动态分派
    virtual void foo() {
        cout << "Base foo()" << endl;
    }
};

class Derived : public Base {
public:
    Derived() {
        cout << "Derived Create" << endl;
    }
    void foo() override {
        cout << "Derived foo()" << endl;
    }
};

int main() {
    Base* b = new Derived();
    b->foo();
    return 0;
}
```

---

#### 属性继承

![image-20240315173101449](C:\Users\37612\AppData\Roaming\Typora\typora-user-images\image-20240315173101449.png)

```JS
const o = {
  a: 1,
  b: 2,
  // __proto__ 设置了 [[Prototype]]。它在这里被指定为另一个对象字面量。
  __proto__: {
    b: 3,
    c: 4,
  },
};
```

这里的console.log(o.\__proto__)输出如图

此时console.log(o.a)输出1，因为o上有自有属性“a”，且其值为1

此时console.log(o.b)输出2，因为o上有自有属性“b”，值为2。原型也有“b“，但未被访问，此称为属性遮蔽(Property Shadowing)

此时console.log(o.c)输出4，虽然o上没有自有属性”c“。但是按照原型链，o.[[prototype]]上有自有属性”c“

console.log(o.d)输出undefined，因为不仅o上没有自有属性”d“，其原型链上直到null都没有自有属性”d“

---

#### 函数继承

```JS
const parent = {
  value: 2,
  method() {
    return this.value + 1;
  },
};

console.log(parent.method()); // 3
// 当调用 parent.method 时，“this”指向了 parent

// child 是一个继承了 parent 的对象
const child = {
  __proto__: parent,
};
console.log(child.method()); // 3
// 调用 child.method 时，“this”指向了 child。
// 又因为 child 继承的是 parent 的方法，
// 首先在 child 上寻找“value”属性。但由于 child 本身
// 没有名为“value”的自有属性，该属性会在
// [[Prototype]] 上被找到，即 parent.value。

child.value = 4; // 在 child，将“value”属性赋值为 4。
// 这会遮蔽 parent 上的“value”属性。
// child 对象现在看起来是这样的：
// { value: 4, __proto__: { value: 2, method: [Function] } }
console.log(child.method()); // 5
// 因为 child 现在拥有“value”属性，“this.value”现在表示
// child.value
```

总结：当继承的函数被调用时，this指针指向的是当前继承的对象，而不是拥有该函数属性的原型对象

---

#### 构造函数

如果一组属性应该出现在每个实例上，例如：

```JS
const boxes = [
  { value: 1, getValue() { return this.value; } },
  { value: 2, getValue() { return this.value; } },
  { value: 3, getValue() { return this.value; } },
];
```

可以将所有的可重用的方法/属性移动到boxes的[[prototype]]，降低内存使用率：

```JS
const boxPrototype = {
  getValue() {
    return this.value;
  },
};

const boxes = [
  { value: 1, __proto__: boxPrototype },
  { value: 2, __proto__: boxPrototype },
  { value: 3, __proto__: boxPrototype },
];
```

可以再度进行优化，使用构造函数，这样就在每个构造的对象设置了[[prototype]]。构造函数是用new调用的函数

```JS
// 一个构造函数
function Box(value) {
  this.value = value;
}

// 使用 Box() 构造函数创建的所有盒子都将具有的属性
Box.prototype.getValue = function () {
  return this.value;
};

const boxes = [new Box(1), new Box(2), new Box(3)];
```

#### 如何正确的继承

```JS
function Person(name) {
    this.name = name;
}

Person.prototype.greet = function() {
    return "Hello, my name is " + this.name;
};

function Student(name, subject) {
    Person.call(this, name);
    this.subject = subject;
}

Student.prototype = Object.create(Person.prototype);
Student.prototype.constructor = Student;

Student.prototype.study = function() {
    return this.name + " is studying " + this.subject;
};

```

这里Student继承Person的关键是：

Student.prototype = Object.create(Person.prototype);

Student.prototype .constructor = Student;

前者表示，通过Object.create(Person.prototype)创建一个新对象，将这个对象的原型设置为Person.prototype。这样Student.prototype对象继承自Person.prototype对象，从而实现了Student构造函数的原型链继承了Person构造函数的原型链的属性和方法。这样在创建Student对象的时候，可以共享Person对象原型链上的属性和方法

后者是为了纠正原型链的一个问题(create()的原因，后续会介绍)，由于Student.prototype是一个新的对象，它的constructor属性会丢失引用到Student函数对象的链接，为了纠正这个错误，需要手动将constructor属性重新指向Student构造函数，以确保原型对象的constructor属性正确地指向其所属的构造函数，并没有改变

-----------------------------------------------------
```JS
在其他地方重新定义Person构造函数的原型对象，并且丢失原来的greet方法
Person.prototype = {sayHi:finction() {return "Hi there!"}}
```

这里已经将Person 构造函数的原型更改了，在这个时候再访问student.greet()，因为greet()是之前Person的原型的方法，而现在Person的原型已经更改了，所以就有可能访问不到(实验的是能访问到，反而是sayHi访问不到)，会出现`TypeError: student.greet is not a function`这个错误。因为constructor被错误地指向了其他构造函数，这些依赖于constructor属性的代码可能会出现问题，导致程序运行错误。这个时候为了防止出现这样的问题，需要我们纠正constructor属性

```JS
Person.prototype = { sayHi: function() { return "Hi there!"; } };
// 这里没有必要手动的纠正 constructor 因为上面的Person.prototype已经将其greet改为sayHi了
Person.prototype.constructor = Person; // 手动纠正 constructor 属性(在运行结果上无区别)
Student.prototype = Object.create(Person.prototype);
Student.prototype.constructor = Student;
Student.prototype.study = function() {
    return this.name + " is studying " + this.subject;
};

let student = new Student("cc", "computer");
console.log(student.study())   // true
console.log(student.sayHi())   // true
console.log(student.greet())   // undefined
```

此时的完整原型链应该是：

```JS
student ---> Student.prototype ---> Person.prototype ---> { greet: function() {...} }
```

#### 字面量的隐式构造

```JS
// 对象字面量（没有 `__proto__` 键）自动将
// `Object.prototype` 作为它们的 `[[Prototype]]`
const object = { a: 1 };
Object.getPrototypeOf(object) === Object.prototype; // true

// 数组字面量自动将 `Array.prototype` 作为它们的 `[[Prototype]]`
const array = [1, 2, 3];
Object.getPrototypeOf(array) === Array.prototype; // true

// 正则表达式字面量自动将 `RegExp.prototype` 作为它们的 `[[Prototype]]`
const regexp = /abc/;
Object.getPrototypeOf(regexp) === RegExp.prototype; // true
```

#### 构建更长的继承链

```JS
function Constructor() {}

const obj = new Constructor();
// obj ---> Constructor.prototype ---> Object.prototype ---> null
```

默认情况下`Constructor.prototype` 是一个*普通对象*，`Object.getPrototypeOf(Constructor.prototype) === Object.prototype`。唯一的例外是 `Object.prototype` 本身，其 `[[Prototype]]` 是 `null`， `Object.getPrototypeOf(Object.prototype) === null`。

那么构造更长的原型链，可以通过setPrototypeOf()方法

```JS
function Base() {}
function Derived() {}
// 将 `Derived.prototype` 的 `[[Prototype]]`
// 设置为 `Base.prototype`
Object.setPrototypeOf(Derived.prototype, Base.prototype);

const obj = new Derived();
// obj ---> Derived.prototype ---> Base.prototype ---> Object.prototype ---> null
```

通过调用`Object.setPrototypeOf(Derived.prototype, Base.prototype)`，告诉JavaScript引擎将Derived.prototype的原型链设置为Base.prototype，这样Derived.prototype会继承Base.prototype上的所有属性和方法。这样就实现了原型链的继承

这样的方式与extends语法等同。

```JS
class Base {}
class Derived extends Base {}

const obj = new Derived();
// obj ---> Derived.prototype ---> Base.prototype ---> Object.prototype ---> null


// 定义父类
class Animal {
  constructor(name) {
    this.name = name;
  }

  speak() {
    console.log(this.name + ' makes a noise.');
  }
}

// 定义子类，继承自父类 Animal
class Dog extends Animal {
  constructor(name) {
    // 在 JavaScript 中，super 关键字用于调用父类（superclass）的构造函数或方法。
    super(name); // 调用父类的构造函数，并将 name 参数传递给父类的构造函数
  }

  speak() {
    console.log(this.name + ' barks.');
  }
}

// 创建一个 Dog 实例
let dog = new Dog('Buddy');
dog.speak(); // 输出 "Buddy barks."
```

还有一些是Object.create()来构建继承链。这个方式会为prototype属性赋值并删除constructor属性，更加容易出错，在构造函数还没有创建任何实例的时候性能提升也不明显。

```JS
// 以下是Object.create()实例
const parent = {
  name: "Parent",
  greet() {
    console.log("Hello, I'm " + this.name);
  }
};

const child = Object.create(parent);
child.name = "Child";
child.greet(); // 输出 "Hello, I'm Child"

child.hasOwnProperty("constructor")  // false
const parentPrototype = Object.getPrototypeOf(parent)
parentPrototype.hasOwnProperty("constructor") // true
// 在JS中hasOwnProperty()方法用于检查对象是否具有特定属性，并不会查找对象的原型链
```

child对象是使用Object.create(paerent)创建的，它的原型链指向了parent对象。这样child对象继承自parent就可以访问到parent对象的属性和方法。

关于为何Object.create()要删除构造函数constructor：

好处：

1、**保持原型继承的一致性和可预测性** Object.create()方法的主要目的是创建一个新对象，使这个对象继承指定对象的属性和方法，通常不需要子对象有自己的构造函数，子对象将继承父对象的构造函数，有助于保持原型继承的一致性和可预测性。

2、**减少内存消耗** 讲构造函数熟悉设置为null或者不指定可以减少对象的内存消耗，不需要再存储构造函数的引用(create并不是将构造函数置为null哦)

坏处：

1. **不一致性：** 如果子对象删除了构造函数属性，而父对象保留了构造函数属性，可能会导致混淆和不一致的行为。尤其是在涉及到类型检查或反射时，程序可能会假设对象具有构造函数属性，从而导致错误。

   ```JS
       function Dog() {
         constructor: {  }
       }
   
       function isDog(obj) {
         return obj.constructor === Dog;
       }
   
       const puppy = new Dog();
       console.log(isDog(puppy)); // 输出 true
   
       // 删除对象的构造函数属性
       puppy.constructor = null
   
       console.log(isDog(puppy)); // 输出 false，因为构造函数属性被删除了
   ```

   

2. **序列化/反序列化问题：** 一些序列化和反序列化库可能依赖于构造函数属性来正确地恢复对象的类型信息。如果构造函数属性被删除，可能会导致反序列化后的对象丢失类型信息或转换为不正确的类型。

   ```JS
       class Person {
         constructor(name, age) {
           this.name = name;
           this.age = age;
         }
       }
       const person = new Person("Alice", 30);
       delete person.constructor
       // person.constructor = null  // 与上面等价
   
       // 序列化对象为字符串
       const serialized = JSON.stringify(person);
   
       // 反序列化字符串为对象
       const deserialized = JSON.parse(serialized);
       console.log(serialized) // 输出 true
       console.log(deserialized) // 输出 true
       console.log(deserialized instanceof Person); // 输出 false
   
   ```

3. **调试困难：** 在调试过程中，构造函数属性通常可以提供有用的信息，例如对象的类型。如果构造函数属性被删除，可能会使调试过程更加困难，因为无法轻松地确定对象的类型。

#### 检查原型

在JS当中函数可以拥有属性

```JS
function doSomething() {}
console.log(doSomething.prototype); // 输出 [object Object]
// 你如何声明函数并不重要；
// JavaScript 中的函数总有一个默认的
// 原型属性——有一个例外：
// 箭头函数没有默认的原型属性：
const doSomethingFromArrowFunction = () => {};
console.log(doSomethingFromArrowFunction.prototype); // 输出 undefined
```

```JS
// 这是doSomething.prototype的对象
{
  constructor: ƒ doSomething(),
  [[Prototype]]: {
    constructor: ƒ Object(),
    hasOwnProperty: ƒ hasOwnProperty(),
    isPrototypeOf: ƒ isPrototypeOf(),
    propertyIsEnumerable: ƒ propertyIsEnumerable(),
    toLocaleString: ƒ toLocaleString(),
    toString: ƒ toString(),
    valueOf: ƒ valueOf()
  }
}
```

下面来做一些练习：

```JS
function doSomething() {}
doSomething.prototype.foo = "bar";
console.log(doSomething.prototype);
```

```
{
  foo: "bar",
  constructor: ƒ doSomething(),
    [[Prototype]]: {
    constructor: ƒ Object(),...
```

---

使用new运算符来创建基于该原型的doSometing()的实例

```JS
function doSomething() {}
doSomething.prototype.foo = "bar"; // 向原型上添加一个属性
const doSomeInstancing = new doSomething();
doSomeInstancing.prop = "some value"; // 向该对象添加一个属性
console.log(doSomeInstancing);
```

```JS
{
  prop: "some value",
  [[Prototype]]: {
    foo: "bar",
    constructor: ƒ doSomething(),
    [[Prototype]]: {
    constructor: ƒ Object(),...
```

---

```JS
function doSomething() {}
doSomething.prototype.foo = "bar";
const doSomeInstancing = new doSomething();
doSomeInstancing.prop = "some value";
console.log("doSomeInstancing.prop:     ", doSomeInstancing.prop);
console.log("doSomeInstancing.foo:      ", doSomeInstancing.foo);
console.log("doSomething.prop:          ", doSomething.prop);
console.log("doSomething.foo:           ", doSomething.foo);
console.log("doSomething.prototype.prop:", doSomething.prototype.prop);
console.log("doSomething.prototype.foo: ", doSomething.prototype.foo);
```

```JS
doSomeInstancing.prop:      some value
doSomeInstancing.foo:       bar
doSomething.prop:           undefined
doSomething.foo:            undefined
doSomething.prototype.prop: undefined
doSomething.prototype.foo:  bar
```

### 使用不同的方法来创建对象和改变原型链

思考: 这些对象的原型链是什么样的？

#### 使用语法结构创建对象

```JS
const o = { a: 1 };
// 新创建的对象 o 以 Object.prototype 作为它的 [[Prototype]]
// Object.prototype 的原型为 null。
// o ---> Object.prototype ---> null

const b = ["yo", "whadup", "?"];
// 数组继承了 Array.prototype（具有 indexOf、forEach 等方法）
// 其原型链如下所示：
// b ---> Array.prototype ---> Object.prototype ---> null

function f() {
  return 2;
}
// 函数继承了 Function.prototype（具有 call、bind 等方法）
// f ---> Function.prototype ---> Object.prototype ---> null

const p = { b: 2, __proto__: o };
// 可以通过 __proto__ 字面量属性将新创建对象的
// [[Prototype]] 指向另一个对象。
// （不要与 Object.prototype.__proto__ 访问器混淆）
// p ---> o ---> Object.prototype ---> null
```

##### 在对象初始化器中使用\__proto__键的优缺点

| 优点 | 被所有的现代引擎所支持。将 `__proto__` 属性指向非对象的值只会被忽略，而非抛出异常。与 [`Object.prototype.__proto__`](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Object/proto) setter 相反，对象字面量初始化器中的 `__proto__` 是标准化，被优化的。甚至可以比 [`Object.create`](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Object/create) 更高效。在创建对象时声明额外的自有属性比 [`Object.create`](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Object/create) 更符合习惯。 |
| :--- | :----------------------------------------------------------- |
| 缺点 | 不支持 IE10 及以下的版本。对于不了解其与 [`Object.prototype.__proto__`](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Object/proto) 访问器差异的人可能会将两者混淆。 |

---

##### 使用构造函数

```JS
function Graph() {
  this.vertices = [];
  this.edges = [];
}

Graph.prototype.addVertex = function (v) {
  this.vertices.push(v);
};

const g = new Graph();
// g 是一个带有自有属性“vertices”和“edges”的对象。
// 在执行 new Graph() 时，g.[[Prototype]] 是 Graph.prototype 的值。
```

| 优点 | 所有引擎都支持——一直到 IE 5.5。此外，其速度很快、非常标准，且极易被 JIT 优化。 |
| :--- | ------------------------------------------------------------ |
| 缺点 | 要使用这个方法，必须初始化该函数。在初始化过程中，构造函数可能会存储每一个对象都必须生成的唯一信息。这些唯一信息只会生成一次，可能会导致问题。构造函数的初始化过程可能会将不需要的方法放到对象上。这两者在实践中通常都不是问题。 |

---

##### 使用Object.create()

```JS
const a = { a: 1 };
// a ---> Object.prototype ---> null

const b = Object.create(a);
// b ---> a ---> Object.prototype ---> null
console.log(b.a); // 1 (inherited)

const c = Object.create(b);
// c ---> b ---> a ---> Object.prototype ---> null

const d = Object.create(null);
// d ---> null（d 是一个直接以 null 为原型的对象）
console.log(d.hasOwnProperty);
// undefined，因为 d 没有继承 Object.prototype
```

| 优点 | 被所有现代引擎所支持。允许在创建时直接设置对象的 `[[Prototype]]`，这允许运行时进一步优化对象。还允许使用 `Object.create(null)` 创建没有原型的对象。 |
| :--- | ------------------------------------------------------------ |
| 缺点 | 不支持 IE8 及以下版本。但是，由于微软已经停止了对运行 IE8 及以下版本的系统的扩展支持，这对大多数应用程序而言应该不是问题。此外，如果使用了第二个参数，慢对象的初始化可能会成为性能瓶颈，因为每个对象描述符属性都有自己单独的描述符对象。当处理上万个对象描述符时，这种延时可能会成为一个严重的问题。 |

---

##### 使用类

```JS
class Polygon {
  constructor(height, width) {
    this.height = height;
    this.width = width;
  }
}

class Square extends Polygon {
  constructor(sideLength) {
    super(sideLength, sideLength);
  }

  // 定义属性的get方法
  get area() {
    return this.height * this.width;
  }
  // 定义属性的set方法
  set sideLength(newLength) {
    this.height = newLength;
    this.width = newLength;
  }
}

const square = new Square(2);
// square ---> Square.prototype ---> Polygon.prototype ---> Object.prototype ---> null
```

| 优点 | 被所有现代引擎所支持。非常高的可读性和可维护性。[私有属性](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Classes/Private_properties)是原型继承中没有简单替代方案的特性。 |
| :--- | ------------------------------------------------------------ |
| 缺点 | 类，尤其是带有私有属性的类，比传统的类的性能要差（尽管引擎实现者正在努力改进这一点）。不支持旧环境，通常需要转译器才能在生产中使用类。 |

---

##### 使用Object.setPrototypeOf()方法

虽然上面的所有方法都会在对象创建时设置原型链，但是 [`Object.setPrototypeOf()`](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Object/setPrototypeOf) 允许修改现有对象的 `[[Prototype]]` 内部属性。(意思是可以强制直接将对象的prototype设置为指定的，貌似对象.\__proto__ = 对象，也可以实现)

| 优点 | 被所有现代引擎所支持。允许动态地修改对象的原型，甚至可以强制为使用 `Object.create(null)` 创建的无原型对象设置原型。 |
| :--- | ------------------------------------------------------------ |
| 缺点 | 性能不佳。如果可以在创建对象时设置原型，则应避免此方法。许多引擎会优化原型，并在调用实例时会尝试提前猜测方法在内存中的位置；但是动态设置原型会破坏这些优化。它可能会导致某些引擎重新编译你的代码以进行反优化，以使其按照规范工作。不支持 IE8 及以下版本。 |

---

##### 使用\__proto__访问器(非标准已弃用，应该使用Object.setPrototypeOf来代替)

所有对象都继承了 [`Object.prototype.__proto__`](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Object/proto) 访问器，它可以用来设置现有对象的 `[[Prototype]]`（如果对象没有覆盖 `__proto__` 属性）。

```JS
const obj = {};
// 请不要使用该方法：仅作为示例。
obj.__proto__ = { barProp: "bar val" };
obj.__proto__.__proto__ = { fooProp: "foo val" };
console.log(obj.fooProp);
console.log(obj.barProp);
```

| 优点 | 被所有现代引擎所支持。将 [`__proto__`](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Object/proto) 设置为非对象的值只会被忽略，而非抛出异常。 |
| :--- | ------------------------------------------------------------ |
| 缺点 | 性能不佳且已被弃用。许多引擎会优化原型，并在调用实例时会尝试提前猜测方法在内存中的位置；但是动态设置原型会破坏这些优化，甚至可能会导致某些引擎重新编译你的代码以进行反优化，以使其按照规范工作。不支持 IE10 及以下版本。[`__proto__`](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Object/proto) 访问器是规范中可选的特性，因此可能无法在所有平台上使用。你几乎总是应该使用 [`Object.setPrototypeOf`](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Object/setPrototypeOf) 代替。 |

#### 性能

原型链上较深层的属性的查找时间可能会对性能产生负面影响，这在性能至关重要的代码中可能会非常明显。此外，尝试访问不存在的属性始终会遍历整个原型链。

此外，在遍历对象的属性时，原型链中的**每个**可枚举属性都将被枚举。要检查对象是否具有在其*自身*上定义的属性，而不是在其原型链上的某个地方，则有必要使用 [`hasOwnProperty`](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Object/hasOwnProperty) 或 [`Object.hasOwn`](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Object/hasOwn) 方法。除 `[[Prototype]]` 为 `null` 的对象外，所有对象都从 `Object.prototype` 继承 [`hasOwnProperty`](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Object/hasOwnProperty)——除非它已经在原型链的更深处被覆盖。



```JS
function Graph() {
  this.vertices = [];
  this.edges = [];
}

Graph.prototype.addVertex = function (v) {
  this.vertices.push(v);
};

const g = new Graph();
// g ---> Graph.prototype ---> Object.prototype ---> null

g.hasOwnProperty("vertices"); // true
Object.hasOwn(g, "vertices"); // true

g.hasOwnProperty("nope"); // false
Object.hasOwn(g, "nope"); // false

// 因为hasOwnProperty和hasOwn是检查对象是否具有在其自身上定义的属性，而addVertex明显是在其prototype上
g.hasOwnProperty("addVertex"); // false
Object.hasOwn(g, "addVertex"); // false

Object.getPrototypeOf(g).hasOwnProperty("addVertex"); // true
```

---

#### Object.assign() vs Object.create()

**Object.assign()：** 用于将一个或多个源对象的所有可枚举属性复制到目标对象，并返回目标对象。如果目标对象中已经存在相同名称的属性，则会被源对象中的属性覆盖。

```JS
const target = { a: 1, b: 2 };
const source = { b: 3, c: 4 };

const merged = Object.assign(target, source);
console.log(merged); // 输出 { a: 1, b: 3, c: 4 }
```

**Object.create()：** 这个方法用于创建一个新对象，新对象的原型（`[[Prototype]]`）由传入的参数决定。如果传入 `null`，则新对象没有原型链。

```JS
const parent = { a: 1 };
const child = Object.create(parent, { b: { value: 2 } });

console.log(child.a); // 输出 1
console.log(child.b); // 输出 2
```

总结：

- `Object.assign()` 用于合并对象的属性到目标对象中(只能复制对象自身的可枚举属性，而不能复制对象的原型链上的属性)。
- `Object.create()` 用于创建一个新对象，可以设置新对象的原型和属性。

```JS
const parent = { a: 1 };
const child = Object.create(parent, { b: { value: 2 } });

// 使用 Object.assign() 合并对象
const merged = Object.assign({}, child);

console.log(merged.a); // 输出 undefined
console.log(merged.b); // 输出 undefined
```

