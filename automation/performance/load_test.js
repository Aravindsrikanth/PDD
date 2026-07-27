import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
    stages: [
        { duration: '10s', target: 100 }, // Ramp up to 100 users
        { duration: '40s', target: 100 }, // Stay at 100 users
        { duration: '10s', target: 0 },   // Ramp down
    ],
    thresholds: {
        http_req_duration: ['p(95)<500'], // 95% of requests must be below 500ms
    },
};

export default function () {
    let res = http.get('https://aravi.github.io/PDD/');
    check(res, {
        'status is 200': (r) => r.status === 200,
        'load time check': (r) => r.timings.duration < 1000,
    });
    sleep(1);
}
