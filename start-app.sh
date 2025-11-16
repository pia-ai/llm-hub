#!/bin/bash

# llm-hub Startup Script
# Description: Start/Stop/Restart the Spring Boot application

# Application configuration
APP_NAME="llm-hub-bootstrap"
APP_VERSION="1.0.0-SNAPSHOT"
JAR_NAME="${APP_NAME}-${APP_VERSION}.jar"
MAIN_CLASS="com.aidoai.llm.hub.Application"

# Path configuration
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_JAR="${BASE_DIR}/app/bootstrap/target/${JAR_NAME}"
PID_FILE="${BASE_DIR}/app.pid"
LOG_DIR="${BASE_DIR}/logs"
LOG_FILE="${LOG_DIR}/llm-hub-app.log"

# JVM configuration
JAVA_OPTS="-server"
JAVA_OPTS="${JAVA_OPTS} -Xms1g"
JAVA_OPTS="${JAVA_OPTS} -Xmx2g"
JAVA_OPTS="${JAVA_OPTS} -XX:MetaspaceSize=128m"
JAVA_OPTS="${JAVA_OPTS} -XX:MaxMetaspaceSize=512m"
JAVA_OPTS="${JAVA_OPTS} -XX:+UseG1GC"
JAVA_OPTS="${JAVA_OPTS} -XX:MaxGCPauseMillis=200"
JAVA_OPTS="${JAVA_OPTS} -XX:+HeapDumpOnOutOfMemoryError"
JAVA_OPTS="${JAVA_OPTS} -XX:HeapDumpPath=${LOG_DIR}/heap_dump.hprof"
JAVA_OPTS="${JAVA_OPTS} -Djava.awt.headless=true"
JAVA_OPTS="${JAVA_OPTS} -Dfile.encoding=UTF-8"
JAVA_OPTS="${JAVA_OPTS} -Duser.timezone=Asia/Shanghai"

# Java 9+ module system configuration for HBase compatibility
# Add opens for HBase to access internal JDK APIs via reflection
JAVA_OPTS="${JAVA_OPTS} --add-opens java.base/java.nio=ALL-UNNAMED"
JAVA_OPTS="${JAVA_OPTS} --add-opens java.base/sun.nio.ch=ALL-UNNAMED"
JAVA_OPTS="${JAVA_OPTS} --add-opens java.base/java.lang=ALL-UNNAMED"
JAVA_OPTS="${JAVA_OPTS} --add-opens java.base/java.lang.reflect=ALL-UNNAMED"
JAVA_OPTS="${JAVA_OPTS} --add-opens java.base/java.util=ALL-UNNAMED"

# Spring Boot configuration
SPRING_OPTS=""
SPRING_PROFILE="${SPRING_PROFILE:-dev}"  # Default to dev profile
SPRING_OPTS="${SPRING_OPTS} --spring.profiles.active=${SPRING_PROFILE}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions

# Check if Java is installed
check_java() {
    if [ -n "$JAVA_HOME" ] && [ -x "$JAVA_HOME/bin/java" ]; then
        JAVA="$JAVA_HOME/bin/java"
    elif command -v java &> /dev/null; then
        JAVA="java"
    else
        echo -e "${RED}Error: Java is not installed or JAVA_HOME is not set${NC}"
        exit 1
    fi
    
    # Check Java version
    JAVA_VERSION=$("$JAVA" -version 2>&1 | awk -F '"' '/version/ {print $2}' | awk -F '.' '{print $1}')
    if [ "$JAVA_VERSION" -lt 17 ]; then
        echo -e "${RED}Error: Java 17 or higher is required${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Java version: $("$JAVA" -version 2>&1 | head -n 1)${NC}"
}

# Check if application is running
is_running() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            return 0
        else
            rm -f "$PID_FILE"
            return 1
        fi
    fi
    return 1
}

# Get application status
status() {
    if is_running; then
        PID=$(cat "$PID_FILE")
        echo -e "${GREEN}Application is running (PID: $PID)${NC}"
        return 0
    else
        echo -e "${YELLOW}Application is not running${NC}"
        return 1
    fi
}

# Start application
start() {
    echo -e "${GREEN}Starting ${APP_NAME}...${NC}"
    
    # Check if already running
    if is_running; then
        echo -e "${YELLOW}Application is already running (PID: $(cat "$PID_FILE"))${NC}"
        exit 1
    fi
    
    # Check Java installation
    check_java
    
    # Check if JAR file exists
    if [ ! -f "$APP_JAR" ]; then
        echo -e "${RED}Error: JAR file not found at $APP_JAR${NC}"
        echo -e "${YELLOW}Please run 'mvn clean package' first${NC}"
        exit 1
    fi
    
    # Create log directory if not exists
    mkdir -p "$LOG_DIR"
    
    # Start application in background
    echo -e "${GREEN}Profile: ${SPRING_PROFILE}${NC}"
    echo -e "${GREEN}JAR: ${APP_JAR}${NC}"
    echo -e "${GREEN}Log: ${LOG_FILE}${NC}"
    
    nohup "$JAVA" $JAVA_OPTS -jar "$APP_JAR" $SPRING_OPTS > /dev/null 2>&1 &
    
    PID=$!
    echo $PID > "$PID_FILE"
    
    # Wait for application to start
    echo -n "Starting"
    for i in {1..30}; do
        if is_running; then
            if curl -s http://localhost:8080/actuator/health > /dev/null 2>&1; then
                echo ""
                echo -e "${GREEN}Application started successfully (PID: $PID)${NC}"
                echo -e "${GREEN}Health check: http://localhost:8080/actuator/health${NC}"
                return 0
            fi
        fi
        echo -n "."
        sleep 1
    done
    
    echo ""
    if is_running; then
        echo -e "${YELLOW}Application started (PID: $PID), but health check failed${NC}"
        echo -e "${YELLOW}Please check logs: tail -f $LOG_FILE${NC}"
    else
        echo -e "${RED}Failed to start application${NC}"
        echo -e "${YELLOW}Please check logs: tail -f $LOG_FILE${NC}"
        exit 1
    fi
}

# Stop application
stop() {
    echo -e "${GREEN}Stopping ${APP_NAME}...${NC}"
    
    if ! is_running; then
        echo -e "${YELLOW}Application is not running${NC}"
        return 0
    fi
    
    PID=$(cat "$PID_FILE")
    echo -e "${GREEN}Stopping application (PID: $PID)${NC}"
    
    # Try graceful shutdown first
    kill -15 "$PID"
    
    # Wait for process to stop
    echo -n "Stopping"
    for i in {1..30}; do
        if ! ps -p "$PID" > /dev/null 2>&1; then
            echo ""
            echo -e "${GREEN}Application stopped successfully${NC}"
            rm -f "$PID_FILE"
            return 0
        fi
        echo -n "."
        sleep 1
    done
    
    # Force kill if still running
    echo ""
    echo -e "${YELLOW}Application did not stop gracefully, forcing shutdown...${NC}"
    kill -9 "$PID"
    sleep 2
    
    if ! ps -p "$PID" > /dev/null 2>&1; then
        echo -e "${GREEN}Application stopped (forced)${NC}"
        rm -f "$PID_FILE"
        return 0
    else
        echo -e "${RED}Failed to stop application${NC}"
        exit 1
    fi
}

# Restart application
restart() {
    echo -e "${GREEN}Restarting ${APP_NAME}...${NC}"
    stop
    sleep 2
    start
}

# Show logs
logs() {
    if [ -f "$LOG_FILE" ]; then
        tail -f "$LOG_FILE"
    else
        echo -e "${RED}Log file not found: $LOG_FILE${NC}"
        exit 1
    fi
}

# Show usage
usage() {
    echo "Usage: $0 {start|stop|restart|status|logs} [options]"
    echo ""
    echo "Commands:"
    echo "  start   - Start the application"
    echo "  stop    - Stop the application"
    echo "  restart - Restart the application"
    echo "  status  - Show application status"
    echo "  logs    - Tail application logs"
    echo ""
    echo "Options:"
    echo "  SPRING_PROFILE=<profile>  - Set Spring profile (default: dev)"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  SPRING_PROFILE=prod $0 start"
    echo "  $0 stop"
    echo "  $0 restart"
    echo "  $0 status"
    echo "  $0 logs"
}

# Main

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    logs)
        logs
        ;;
    *)
        usage
        exit 1
        ;;
esac

exit 0

