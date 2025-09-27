
import fetch from 'node-fetch';

import { Base } from './Base';
import { Calendar } from './Calendar';
import { CalendarEvent } from './CalendarEvent';
import { Attendee } from './Attendee';
import { AttendeeLog } from './AttendeeLog';
import { EventDoc } from './EventDoc';
import { EventLocation } from './EventLocation';
import { ChatGroup } from './ChatGroup';
import { ChatMessage } from './ChatMessage';
import { MessageLink } from './MessageLink';
import { MessageReaction } from './MessageReaction';
import { Contact } from './Contact';
import { Group } from './Group';
import { GroupMember } from './GroupMember';
import { Message } from './Message';
import { SendLog } from './SendLog';
import { Planning } from './Planning';
import { PlanningRecurrenceRule } from './PlanningRecurrenceRule';
import { Profile } from './Profile';
import { Experience } from './Experience';
import { Education } from './Education';
import { Project } from './Project';
import { Swimlane } from './Swimlane';
import { Milestone } from './Milestone';
import { ProjectIssue } from './ProjectIssue';
import { RegistrationDesk } from './RegistrationDesk';
import { RegistrationFileAttachment } from './RegistrationFileAttachment';
import { Registration } from './Registration';
import { User } from './User';

export class HeroModelsClient {
    private baseUrl: string;

    constructor(baseUrl: string = 'http://localhost:8086/api/heromodels') {
        this.baseUrl = baseUrl;
    }

    private async send<T>(method: string, params: any): Promise<T> {
        const response = await fetch(this.baseUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                jsonrpc: '2.0',
                method: method,
                params: params,
                id: 1,
            }),
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const jsonResponse:any = await response.json();
        if (jsonResponse.error) {
            throw new Error(`RPC error: ${jsonResponse.error.message}`);
        }

        return jsonResponse.result;
    }

    async calendar_get(params: { id: number }): Promise<Calendar> {
        return this.send('calendar_get', params);
    }

    async calendar_set(params: { calendar: Calendar, events: any[], color: string, timezone: string, is_public: boolean }): Promise<number> {
        return this.send('calendar_set', params);
    }

    async calendar_delete(params: { id: number }): Promise<boolean> {
        return this.send('calendar_delete', params);
    }

    async calendar_exist(params: { id: number }): Promise<boolean> {
        return this.send('calendar_exist', params);
    }

    async calendar_list(params: {  }): Promise<any[]> {
        return this.send('calendar_list', params);
    }

    async calendar_event_get(params: { id: number }): Promise<CalendarEvent> {
        return this.send('calendar_event_get', params);
    }

    async calendar_event_set(params: { calendar_event: CalendarEvent }): Promise<number> {
        return this.send('calendar_event_set', params);
    }

    async calendar_event_delete(params: { id: number }): Promise<boolean> {
        return this.send('calendar_event_delete', params);
    }

    async calendar_event_exist(params: { id: number }): Promise<boolean> {
        return this.send('calendar_event_exist', params);
    }

    async calendar_event_list(params: {  }): Promise<any[]> {
        return this.send('calendar_event_list', params);
    }

    async chat_group_get(params: { id: number }): Promise<ChatGroup> {
        return this.send('chat_group_get', params);
    }

    async chat_group_set(params: { chat_group: ChatGroup }): Promise<number> {
        return this.send('chat_group_set', params);
    }

    async chat_group_delete(params: { id: number }): Promise<boolean> {
        return this.send('chat_group_delete', params);
    }

    async chat_group_exist(params: { id: number }): Promise<boolean> {
        return this.send('chat_group_exist', params);
    }

    async chat_group_list(params: {  }): Promise<any[]> {
        return this.send('chat_group_list', params);
    }

    async chat_message_get(params: { id: number }): Promise<ChatMessage> {
        return this.send('chat_message_get', params);
    }

    async chat_message_set(params: { chat_message: ChatMessage }): Promise<number> {
        return this.send('chat_message_set', params);
    }

    async chat_message_delete(params: { id: number }): Promise<boolean> {
        return this.send('chat_message_delete', params);
    }

    async chat_message_exist(params: { id: number }): Promise<boolean> {
        return this.send('chat_message_exist', params);
    }

    async chat_message_list(params: {  }): Promise<any[]> {
        return this.send('chat_message_list', params);
    }

    async contact_get(params: { id: number }): Promise<Contact> {
        return this.send('contact_get', params);
    }

    async contact_set(params: { contact: Contact }): Promise<number> {
        return this.send('contact_set', params);
    }

    async contact_delete(params: { id: number }): Promise<boolean> {
        return this.send('contact_delete', params);
    }

    async contact_exist(params: { id: number }): Promise<boolean> {
        return this.send('contact_exist', params);
    }

    async contact_list(params: {  }): Promise<any[]> {
        return this.send('contact_list', params);
    }

    async group_get(params: { id: number }): Promise<Group> {
        return this.send('group_get', params);
    }

    async group_set(params: { group: Group }): Promise<number> {
        return this.send('group_set', params);
    }

    async group_delete(params: { id: number }): Promise<boolean> {
        return this.send('group_delete', params);
    }

    async group_exist(params: { id: number }): Promise<boolean> {
        return this.send('group_exist', params);
    }

    async group_list(params: {  }): Promise<any[]> {
        return this.send('group_list', params);
    }

    async message_get(params: { id: number }): Promise<Message> {
        return this.send('message_get', params);
    }

    async message_set(params: { message: Message }): Promise<number> {
        return this.send('message_set', params);
    }

    async message_delete(params: { id: number }): Promise<boolean> {
        return this.send('message_delete', params);
    }

    async message_exist(params: { id: number }): Promise<boolean> {
        return this.send('message_exist', params);
    }

    async message_list(params: {  }): Promise<any[]> {
        return this.send('message_list', params);
    }

    async planning_get(params: { id: number }): Promise<Planning> {
        return this.send('planning_get', params);
    }

    async planning_set(params: { planning: Planning }): Promise<number> {
        return this.send('planning_set', params);
    }

    async planning_delete(params: { id: number }): Promise<boolean> {
        return this.send('planning_delete', params);
    }

    async planning_exist(params: { id: number }): Promise<boolean> {
        return this.send('planning_exist', params);
    }

    async planning_list(params: {  }): Promise<any[]> {
        return this.send('planning_list', params);
    }

    async profile_get(params: { id: number }): Promise<Profile> {
        return this.send('profile_get', params);
    }

    async profile_set(params: { profile: Profile }): Promise<number> {
        return this.send('profile_set', params);
    }

    async profile_delete(params: { id: number }): Promise<boolean> {
        return this.send('profile_delete', params);
    }

    async profile_exist(params: { id: number }): Promise<boolean> {
        return this.send('profile_exist', params);
    }

    async profile_list(params: {  }): Promise<any[]> {
        return this.send('profile_list', params);
    }

    async project_get(params: { id: number }): Promise<Project> {
        return this.send('project_get', params);
    }

    async project_set(params: { project: Project }): Promise<number> {
        return this.send('project_set', params);
    }

    async project_delete(params: { id: number }): Promise<boolean> {
        return this.send('project_delete', params);
    }

    async project_exist(params: { id: number }): Promise<boolean> {
        return this.send('project_exist', params);
    }

    async project_list(params: {  }): Promise<any[]> {
        return this.send('project_list', params);
    }

    async project_issue_get(params: { id: number }): Promise<ProjectIssue> {
        return this.send('project_issue_get', params);
    }

    async project_issue_set(params: { project_issue: ProjectIssue }): Promise<number> {
        return this.send('project_issue_set', params);
    }

    async project_issue_delete(params: { id: number }): Promise<boolean> {
        return this.send('project_issue_delete', params);
    }

    async project_issue_exist(params: { id: number }): Promise<boolean> {
        return this.send('project_issue_exist', params);
    }

    async project_issue_list(params: {  }): Promise<any[]> {
        return this.send('project_issue_list', params);
    }

    async registration_desk_get(params: { id: number }): Promise<RegistrationDesk> {
        return this.send('registration_desk_get', params);
    }

    async registration_desk_set(params: { registration_desk: RegistrationDesk }): Promise<number> {
        return this.send('registration_desk_set', params);
    }

    async registration_desk_delete(params: { id: number }): Promise<boolean> {
        return this.send('registration_desk_delete', params);
    }

    async registration_desk_exist(params: { id: number }): Promise<boolean> {
        return this.send('registration_desk_exist', params);
    }

    async registration_desk_list(params: {  }): Promise<any[]> {
        return this.send('registration_desk_list', params);
    }

    async user_get(params: { id: number }): Promise<User> {
        return this.send('user_get', params);
    }

    async user_set(params: { user: User }): Promise<number> {
        return this.send('user_set', params);
    }

    async user_delete(params: { id: number }): Promise<boolean> {
        return this.send('user_delete', params);
    }

    async user_exist(params: { id: number }): Promise<boolean> {
        return this.send('user_exist', params);
    }

    async user_list(params: {  }): Promise<any[]> {
        return this.send('user_list', params);
    }

}
