# Objective-C学习

[Objective-C 菜鸟教程](https://www.runoob.com/w3cnote/objective-c-tutorial.html)

#### Objective-C文件扩展名

| 扩展名 | 内容类型                                                     |
| ------ | ------------------------------------------------------------ |
| .h     | 头文件。包含类，类型，函数和常数的声明                       |
| .m     | 源代码文件。可以包含Objective-C和C代码                       |
| .mm    | 源代码文件。除了包含Objective-C和C代码还可以包含C++代码。<br />(仅在Objective-C代码中确实需要使用C++类或者特性的时候才这个) |

包含头文件可以使用#include编译选项，Objective-C提供了一个更好的:#import。

#import与#include选项完全一样，但是#import可以确保相同的文件只会被包含一次。尽量用这个

#### 消息传递

比较Objective-C与C++的消息传递机制与区别

###### Objective-C消息传递机制：

- 通过使用符号'<b>[ ]</b>'向对象发送消息给对象，例如<b>[object method]</b>
- 在编译的时候，Objective-C不会检查对象是否真正拥有要调用的方法，是在运行时动态查
- 一个类别不保证一定会回应收到的消息，若收到了一个无法处理的消息，运行时系统会调用`doesNotRecognizeSelector`方法或者抛出异常，不会出错或崩溃

###### C++消息传递机制

- 通过使用'<b> . </b>'符号来调用对象的成员函数，例如<b>object.method()</b>
- 在编译的时候，C++会检查对象是否拥有将要调用的成员函数，并确保调用函数是合法的。
- 若调用一个未定义的成员函数，编译器会报错

C++强制要求所有方法必须有对应的动作，且编译期绑定使得函数调用非常快速。缺点是仅能借由virtual关键词提供有限的动态绑定能力。

Objective-C天然具备动态绑定能力，因为运行期才处理消息，允许发送未知消息给对象。可以传递参数给整个对象集合而不需要检查每个对象的类型，也具备消息传送机制。同时空对象nil接收消息后默认认为不做事，所以送消息给nil也不用担心程序崩溃。

---

#### 字符串

Objective-C支持C语言字符串约定: 单字符被单引用包括，字符串被双括号包括。但是通常不使用C语言风格的字符串，大多数框架把字符串传递给NSString对象。NSString类提供了字符串的类包装，要使用这个助记符，只需要在普通的双引号字符串前放置一个 <b>@</b> 符号。

```objective-c
NSString* myString = @"My String\n";
NSString* anotherString = [NSString stringWithFormat:@"%d %s", 1, @"String"];

// 从一个C语言字符串创建Objective-C字符串
NSString*  fromCString = [NSString stringWithCString:"A C string" 
encoding:NSASCIIStringEncoding];
```

使用NSString类的优点: 

- <b>面向对象：</b>NSString是Objective-C中的一个类，其提供了丰富的字符串处理方法和属性，可以更加方便地进行字符串拼接、比较、截取、搜索、替换、格式化等操作，无需手动处理字符数组。0
- <b>内存管理：</b>NSString基于引用技术的内存管理模型，使用自动引用计数(ARC)来管理内存，无需我们手动管理字符串的分配和释放。C语言字符串需要手动分配和释放内存，容易出现内存泄漏或越界访问等问题。
- <b>Unicode支持：</b>NSString内部使用Unicode编码来表示字符串，可以更加方便地处理各种语言、特殊字符和表情符号。C语言字符串基于ASCII/UTF-8编码，可能无法完全支持Unicode字符。

---

#### 类

Objective-C的类的规格说明包含了两个部分：定义(interface)与实现(implementation)。

类申明总是以@interface编译选项开始，由@end编译选项结束。类名之后的(用冒号分割的)是父类的名字。类的实例(或者成员)变量声明在被大括号包含的代码块中。实例变量块后面就是类声明的方法的列表。每个实例变量和方法声明都以分号结尾。

##### Interface

定义部分，清楚定义了类的名称、数据成员和方法。以@interface开始，@end结束。

```objective-c
@interface MyObject : NSObject {
    int memberVar1; // 实体变量
    id  memberVar2;
}

+(return_type) class_method; // 类方法

-(return_type) instance_method1; // 实例方法
-(return_type) instance_method2: (int) p1;
-(return_type) instance_method3: (int) p1 andPar: (int) p2;
@end
```

方法前面的+/-代表函数的类型：加号(+)代表类方法，不需要实例就可以调用，与C++的静态函数(static member function)相似。减号(-)即是一般的实例方法(instance method)。

这里可以看见Objective-C传参的时候是使用冒号<b>:</b> 来实现传参的。例如一个设置颜色的函数:

````objective-c
(void) setColorToRed: (float)red Green: (float)green Blue:(float)blue; // 方法
// 这个方法的名称是setColorToRed:Green:Blue
// 每个冒号后都带着一个float类型的参数，分别代表红，绿，蓝三色

[myColor setColorToRed: 1.0 Green: 0.8 Blue: 0.2]; /* 调用方法*/
````

##### Implementation

实现部分，包含了公开方法的实现，以及定义私有(private)变量及方法。以关键字@implementation开始，@end结束。

```objective-c
// 定义私有变量
@implementation MyObject {
    int memberVar3;  // 定义私有变量 
}

+(return_type) class_method {
    .... //method implementation
}
-(return_type) instance_method1 {
     ....
}
-(return_type) instance_method2: (int) p1 {
    ....
}
-(return_type) instance_method3: (int) p1 andPar: (int) p2 {
    ....
}
@end
```

Tips：在interface当中定义的实体变量默认权限是protected，在implementation当中定义的实体变量默认权限是private。

##### 创建对象

Objective-C通过alloc和init这两个消息创建对象。alloc是分配内存，init是初始化对象。这两者都是i定义在NSObject中的方法，父对象收到这两个信息并做出正确回应后，新对象才创建完毕。

```Objective-c
MyObject * my = [[MyObject alloc] init];

// 在Objective-C 2.0中，若创建对象不需要参数的时候，可以直接使用new
MyObject * my = [MyObject new];
```

Tips：若需要自己定义初始化的过程，可以重写init方法(类似于C++的构造函数constructor)

---

#### 方法

