#!/bin/bash

if [ $# -eq 0 ]; then
    echo "사용법: $0 <포트 번호>"
    exit 1
fi

PORT=$1

# 포트를 사용 중인 프로세스의 PID 찾기
PID=$(lsof -i :$PORT -t)

if [ -z "$PID" ]; then
    echo "포트 $PORT를 사용 중인 프로세스를 찾을 수 없습니다."
    exit 1
fi

echo "포트 $PORT를 사용 중인 프로세스 (PID: $PID)를 종료합니다."

# 프로세스 종료
kill -9 $PID

if [ $? -eq 0 ]; then
    echo "프로세스가 성공적으로 종료되었습니다."
else
    echo "프로세스 종료에 실패했습니다."
fi