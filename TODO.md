
# TODO 리스트

1. 채팅 시스템 구축
 - 최초 회원가입시 로직 추가되었음. -> 이부분 검증이 필요함.

2. 백엔드 리스트 페이징 처리하기
 - 알림리스트 api
 - 내정보 > 내 게시물 페이징 처리
 - 내정보 > 팔로우 페이징 처리

3. CCTV 상세 화면 보기 
 - 서울지역 상세 video화면 수정

4. 글쓰기/팔로우 시 메세지 보내기
 - 푸쉬

5. 파이어베이스 테스트
 - 푸쉬

6. 회원가입 테스트
  - 카/네이버 회원가입시 전화번호 없이 가입 가능한지 테스트?

7. 공지사항/FAQ/ 개인정보처리방칩/위치기반서비스 등 내용 현실화 데이터로 적재

8. 메인 영상리스트 가져오기 수정
  - 무한 페이징 및 데이터 가져오기

[완료] 9. 회원 이미지 변경 api 개발
 - 

10. 날씨 이미지 변경
 - https://peter-codinglife.tistory.com/70
 - https://gist.github.com/choipd/e73201a4653a5e56e830


  GRANT ALL PRIVILEGES ON *.* TO 'db_user1'@'211.45.167.195' IDENTIFIED BY 'aaaAAA111!!!';






  SELECT  
                C.CUST_ID as  custId , 
                C.CUST_NM as  custNm , 
                C.NICK_NM as  nickNm , 
                C.PROFILE_PATH as  profilePath , 
                A.BOARD_ID as boardId , 
                A.TYPE_CD as typeCd , 
                A.TYPE_DT_CD as typeDtCd , 
                A.PARENT_ID as parentId , 
                A.SUBJECT as subject , 
                A.CONTENTS as contents , 
                A.DEPTH_NO as depthNo, 
                A.CRT_DTM as crtDtm, 
                B.LAT as lat , 
                B.LON as lon , 
                B.LOCATION as location , 
                B.WEATHER_INFO as weatherInfo, 
                B.VIDEO_PATH as videoPath , 
                B.THUMBNAIL_PATH as thumbnailPath , 
                B.ICON as icon , 
                B.CURRENT_TEMP as currentTemp, 
                B.TEMP_MIN as tempMin, 
                B.TEMP_MAX as tempMax, 
                B.HUMIDITY as humidity , 
                B.SPEED as speed , 
                B.COUNTRY as country , 
                B.CITY as city , 
                B.FEELS_TEMP as feelsTemp , 
                B.VIDEO_ID as videoId , 
                (select Count(1) from TB_BOARD_MASTER as T_BOARD where T_BOARD.PARENT_ID = A.BOARD_ID) as replyCnt ,  
                (select Count(1) from TB_BOARD_LIKE as T_LIKE where T_LIKE.BOARD_ID = A.BOARD_ID) as likeCnt ,  
                (select Count(1) from TB_BOARD_VIEW as T_VIEW where T_VIEW.BOARD_ID = A.BOARD_ID) as viewCnt ,  
                (select if(Count(1) = 0, 'N', 'Y') from TB_BOARD_LIKE as T_LIKE where T_LIKE.BOARD_ID = A.BOARD_ID AND T_LIKE.CUST_ID = :#{#searchBoardInVo.custId}) as likeYn ,  
                (select if(Count(1) = 0, 'N', 'Y') from TB_BOARD_FOLLOW as T_FOLLOW where T_FOLLOW.CUST_ID = :#{#searchBoardInVo.custId} AND T_FOLLOW.FOLLOW_CUST_ID = C.CUST_ID ) as followYn ,  
                (ST_DISTANCE_SPHERE(point(:#{#searchBoardInVo.lon}, :#{#searchBoardInVo.lat}), point(B.Lon, B.LAT)) / 1000) as distance    
            FROM TB_BOARD_MASTER A, 
                 TB_BOARD_WEATHER B,  
                 TB_CUST_MASTER C  
            WHERE A.BOARD_ID = B.BOARD_ID  
              and A.PARENT_ID = '0' 
              and A.CRT_CUST_ID = C.CUST_ID  
              and ST_DISTANCE_SPHERE(point(:#{#searchBoardInVo.lon}, :#{#searchBoardInVo.lat}), point(B.Lon, B.LAT)) < :#{#searchBoardInVo.radiansKm} * 1000   
              and A.DEL_YN = 'N'   
            ORDER BY  A.CRT_DTM DESC , ST_DISTANCE_SPHERE(point(:#{#searchBoardInVo.lon}, :#{#searchBoardInVo.lat}), point(B.Lon, B.LAT)) ASC





            SELECT  
    C.CUST_ID as custId, 
    C.CUST_NM as custNm, 
    C.NICK_NM as nickNm, 
    C.PROFILE_PATH as profilePath, 
    A.BOARD_ID as boardId, 
    A.TYPE_CD as typeCd, 
    A.TYPE_DT_CD as typeDtCd, 
    A.PARENT_ID as parentId, 
    A.SUBJECT as subject, 
    A.CONTENTS as contents, 
    A.DEPTH_NO as depthNo, 
    A.CRT_DTM as crtDtm, 
    B.LAT as lat, 
    B.LON as lon, 
    B.LOCATION as location, 
    B.WEATHER_INFO as weatherInfo, 
    B.VIDEO_PATH as videoPath, 
    B.THUMBNAIL_PATH as thumbnailPath, 
    B.ICON as icon, 
    B.CURRENT_TEMP as currentTemp, 
    B.TEMP_MIN as tempMin, 
    B.TEMP_MAX as tempMax, 
    B.HUMIDITY as humidity, 
    B.SPEED as speed, 
    B.COUNTRY as country, 
    B.CITY as city, 
    B.FEELS_TEMP as feelsTemp, 
    B.VIDEO_ID as videoId, 
    replyCnt.replyCount, 
    likeCnt.likeCount, 
    viewCnt.viewCount, 
    CASE WHEN likeYn.likeExists IS NULL THEN 'N' ELSE 'Y' END as likeYn, 
    CASE WHEN followYn.followExists IS NULL THEN 'N' ELSE 'Y' END as followYn, 
    distanceCalc.distance / 1000 as distance 
FROM 
    TB_BOARD_MASTER A 
JOIN 
    TB_BOARD_WEATHER B ON A.BOARD_ID = B.BOARD_ID 
JOIN 
    TB_CUST_MASTER C ON A.CRT_CUST_ID = C.CUST_ID 
LEFT JOIN 
    (SELECT PARENT_ID, COUNT(1) as replyCount FROM TB_BOARD_MASTER GROUP BY PARENT_ID) replyCnt ON A.BOARD_ID = replyCnt.PARENT_ID 
LEFT JOIN 
    (SELECT BOARD_ID, COUNT(1) as likeCount FROM TB_BOARD_LIKE GROUP BY BOARD_ID) likeCnt ON A.BOARD_ID = likeCnt.BOARD_ID 
LEFT JOIN 
    (SELECT BOARD_ID, COUNT(1) as viewCount FROM TB_BOARD_VIEW GROUP BY BOARD_ID) viewCnt ON A.BOARD_ID = viewCnt.BOARD_ID 
LEFT JOIN 
    (SELECT BOARD_ID, CUST_ID, 'Y' as likeExists FROM TB_BOARD_LIKE WHERE CUST_ID = :#{#searchBoardInVo.custId}) likeYn ON A.BOARD_ID = likeYn.BOARD_ID 
LEFT JOIN 
    (SELECT FOLLOW_CUST_ID, CUST_ID, 'Y' as followExists FROM TB_BOARD_FOLLOW WHERE CUST_ID = :#{#searchBoardInVo.custId}) followYn ON C.CUST_ID = followYn.FOLLOW_CUST_ID 
CROSS JOIN 
    (SELECT ST_DISTANCE_SPHERE(POINT(:#{#searchBoardInVo.lon}, :#{#searchBoardInVo.lat}), POINT(B.LON, B.LAT)) as distance 
     FROM TB_BOARD_WEATHER B 
     WHERE B.BOARD_ID = A.BOARD_ID) distanceCalc 
WHERE 
    A.PARENT_ID = '0' 
    AND A.DEL_YN = 'N' 
    AND ST_DISTANCE_SPHERE(POINT(:#{#searchBoardInVo.lon}, :#{#searchBoardInVo.lat}), POINT(B.LON, B.LAT)) < :#{#searchBoardInVo.radiansKm} * 1000 
ORDER BY 
    A.CRT_DTM DESC, 
    distance ASC;