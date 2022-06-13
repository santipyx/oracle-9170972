# Spring Boot Hello World Example
Based on https://mkyong.com/spring-boot/spring-boot-hello-world-example/

# Incident Report 9170972
## Steps to Reproduce the problem
### 1) Build the image
You can execute the following command
`docker build -t class_loader_problem .`

### 2) Run the container image
`docker run -d -p 8080:8080 --name class_loader_reproducer class_loader_problem:latest`

### 3) Check the logs
`docker logs -f class_loader_reproducer`

### 4) Logs
We are seeing a lot of Warnings related to Java_java_lang_ClassLoader_00024NativeLibrary_load and is flooding our log console. This message appears every few seconds

2022-06-10 15:39:06.963  INFO 20 --- [ main] com.mkyong.MyWebApplication: Started MyWebApplication in 2.457 seconds (JVM running for 5.043)
WARNING: Could not find Java_java_lang_ClassLoader_00024NativeLibrary_load
WARNING: Could not find Java_java_lang_ClassLoader_00024NativeLibrary_load
WARNING: Could not find Java_java_lang_ClassLoader_00024NativeLibrary_load
WARNING: Could not find Java_java_lang_ClassLoader_00024NativeLibrary_load

This could be related to the last changes made in [github.com/openjdk/jdk11u](https://github.com/openjdk/jdk11u/commit/f7346f087a14f1878029a00104005e04468d333f) under the ClassLoader.c file

We are also seeing other reports with the same problem in [stackoverflow](https://stackoverflow.com/questions/72178216/java-error-java-java-lang-classloader-00024nativelibrary-load0)