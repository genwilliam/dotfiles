# 设置的别名


# python
# alias python=python3
# alias pip=pip3

# git
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'


alias ll='ls -lh'
alias la='ls -a'


# java & maven
# Maven 21 引擎 (支持 Spring Boot 运行及打包)
# 注意：使用 \$PWD 确保每次运行命令时都动态获取当前路径
alias m21='docker run -it --rm \
  -p 8080:8080 \
  -v /Users/william/Developer/tools/mvn_repository:/root/.m2 \
  -v "$PWD":/usr/src/app \
  -w /usr/src/app \
  --add-host=host.docker.internal:host-gateway \
  maven:3.9-eclipse-temurin-21 \
  mvn'

# Maven 8 引擎
alias m8='docker run -it --rm \
  -v /Users/william/Developer/tools/mvn_repository:/root/.m2 \
  -v "$PWD":/usr/src/app \
  -w /usr/src/app \
  --add-host=host.docker.internal:host-gateway \
  maven:3.9-eclipse-temurin-8 \
  mvn'

# 使用 JDK 21 作为系统默认 java/javac 引擎
alias java21='docker run -it --rm -v "$PWD":/app -w /app eclipse-temurin:21 java'
alias javac21='docker run -it --rm -v "$PWD":/app -w /app eclipse-temurin:21 javac'

# 如果偶尔需要用 JDK 8，可以保留带版本号的别名作为备选
alias java8='docker run -it --rm -v "$PWD":/app -w /app eclipse-temurin:8-jdk java'
alias javac8='docker run -it --rm -v "$PWD":/app -w /app eclipse-temurin:8-jdk javac'

