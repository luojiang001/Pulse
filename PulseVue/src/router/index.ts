import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'
import Home from '@/views/admin/Home.vue';
import Register from '@/views/admin/Register.vue';
import Medicine from '@/views/admin/Medicine.vue';
import Doctor from '@/views/admin/Doctor.vue';
import Order from '@/views/admin/Order.vue';
import Setting from '@/views/admin/Setting.vue';
import Work from '@/views/doctor/Work.vue';
import Record from '@/views/doctor/Record.vue';
import Schedule from '@/views/doctor/Schedule.vue';
import User from '@/views/admin/User.vue';
import Announcement from '@/views/admin/Announcement.vue';
import Personal from '@/views/doctor/Personal.vue';
import Chat from '@/views/doctor/Chat.vue';

const routes: RouteRecordRaw[] = [
    {
        path: '/',
        meta: { username: 'login' },
        component: () => import('@/views/login.vue'),
    },
    {
        path: '/admin',
        meta: { username: 'admin' },
        component: () => import('@/views/admin/AdminHome.vue'),
        children: [
            { path: 'home', meta: { username: 'Home' }, component: Home },
            { path: 'register', meta: { username: 'Register' }, component: Register },
            { path: 'medicine', meta: { username: 'Medicine' }, component: Medicine },
            { path: 'user', meta: { username: 'User' }, component: User },
            { path: 'doctor', meta: { username: 'Doctor' }, component: Doctor },
            { path: 'order', meta: { username: 'Order' }, component: Order },
            { path: 'announcement', meta: { username: 'Announcement' }, component: Announcement },
            { path: 'setting', meta: { username: 'Setting' }, component: Setting },
        ]
    },
    {
        path: '/doctor',
        meta: { username: 'doctor' },
        component: () => import('@/views/doctor/DoctorHome.vue'),
        children: [
            { path: 'work', meta: { username: 'Work' }, component: Work },
            { path: 'record', meta: { username: 'Record' }, component: Record },
            { path: 'schedule', meta: { username: 'Schedule' }, component: Schedule },
            { path: 'chat', meta: { username: 'Chat' }, component: Chat },
            { path: 'personal', meta: { username: 'Personal' }, component: Personal },
        ]
    },
];

const router = createRouter({
    history: createWebHistory(import.meta.env.BASE_URL),
    routes
});

// 全局路由守卫，拦截未登录
router.beforeEach((to, from, next) => {
    if (to.path === '/') {
        next();
        return;
    }

    const adminInfo = sessionStorage.getItem('adminInfo');
    const doctorInfo = sessionStorage.getItem('doctorInfo');

    if (to.path.startsWith('/admin')) {
        if (adminInfo) {
            next();
        } else {
            next('/');
        }
    } else if (to.path.startsWith('/doctor')) {
        if (doctorInfo) {
            next();
        } else {
            next('/');
        }
    } else {
        next('/');
    }
});

export default router;