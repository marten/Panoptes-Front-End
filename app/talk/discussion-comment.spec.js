import React from 'react';
import assert from 'assert';
import DiscussionComment from './discussion-comment';
import CommentBox from './comment-box';
import { shallow } from 'enzyme';

const discussion = {
  section: 1
};

const user = {
  id: 1,
  display_name: 'Test User'
};

describe('DiscussionComment', function() {
  let wrapper;

  describe('not logged in', function() {
    it('will ask user to sign in', function() {
      wrapper = shallow(<DiscussionComment discussion={discussion} user={null} />);
      assert.equal(wrapper.find('.talk-comment-author').length, 0);
      assert.equal(wrapper.contains(
        <button
          className="link-style"
          type="button"
          onClick={wrapper.instance().promptToSignIn} >
            sign in
        </button>),
        true);
    });
  });

  describe('logged in', function() {
    beforeEach(function(){
      wrapper = shallow(<DiscussionComment discussion={discussion} user={user} />);
    });

    it('will show a user avatar', function() {
      assert.equal(wrapper.find('.talk-comment-author').length, 1);
    });
    it('will show a comment box', function(){
      assert.equal(wrapper.find(CommentBox).props().user, user);
    })
  });
});
