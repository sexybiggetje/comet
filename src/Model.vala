namespace Comet {

    public class Model : Object {

        public string original_text { get; private set; }

        public string message { get; private set; }
        public Gtk.TextBuffer message_buffer { get; private set; }

        public string comment { get; private set; }
        public Gtk.TextBuffer comment_buffer { get; private set; }

        private string commit_message_file_path;

        public bool initialise_with_commit_message_file (File commit_message_file) throws FileError {
            commit_message_file_path = commit_message_file.get_path ();

            //
            // Ascertain type of git message from its file path.
            //

            // Generic commit message.
            var is_git_commit_message = commit_message_file_path.index_of ("COMMIT_EDITMSG") > -1;
            var is_test_commit_message = commit_message_file_path.index_of ("tests/message-with-body") > -1
                || commit_message_file_path.index_of ("tests/message-without-body") > -1;
            var is_commit_message = is_git_commit_message || is_test_commit_message;

            // Git merge message.
            var is_git_merge_message = commit_message_file_path.index_of ("MERGE_MSG") > -1;
            var is_test_merge_message = commit_message_file_path.index_of ("tests/merge") > -1;
            var is_merge_message = is_git_merge_message || is_test_merge_message;

            // Git tag message.
            var is_git_tag_message  = commit_message_file_path.index_of ("TAG_EDITMSG") > -1;
            var is_test_tag_message = commit_message_file_path.index_of ("tests/tag-message") > -1;
            var is_tag_message = is_git_tag_message || is_test_tag_message;

            // AddP Hunk Edit message.
            var is_git_add_p_hunk_edit_message = commit_message_file_path.index_of ("addp-hunk-edit.diff") > -1;
            var is_test_add_p_hunk_edit_message = commit_message_file_path.index_of ("tests/add-p-edit-hunk") > -1;
            var is_add_p_hunk_edit_message = is_git_add_p_hunk_edit_message || is_test_add_p_hunk_edit_message;

            // Rebase message.
            var is_git_rebase_message = commit_message_file_path.index_of ("rebase-merge/git-rebase-todo") > -1;
            var is_test_rebase_message = commit_message_file_path.index_of ("tests/rebase") > -1;
            var is_rebase_message = is_git_rebase_message || is_test_rebase_message;

            var is_test = is_test_commit_message || is_test_tag_message || is_test_add_p_hunk_edit_message || is_test_rebase_message || is_test_merge_message;


            print (@"Is git commit message: $(is_git_commit_message)");
            print (@"Is test commit message: $(is_test_commit_message)");
            print (@"Is commit message: $(is_commit_message)");

            string commit_message_file_contents;
            size_t commit_message_file_length;

            FileUtils.get_contents (commit_message_file_path, out commit_message_file_contents, out commit_message_file_length);

            print (@"File path: $(commit_message_file_path)\n");
            print (@"Contents: \n\n $(commit_message_file_contents)\n");

            original_text = commit_message_file_contents;

            var text = original_text;

            // Escape tag start/end as we will be using markup to populate the buffer.
            // (Otherwise, rebase -i commit messages fail, as they contain the strings
            // <commit>, <label>, etc.
            try {
                var all_left_angular_brackets = new Regex (Regex.escape_string ("<"));
                var all_right_angular_brackets = new Regex ( Regex.escape_string (">"));
                text = all_left_angular_brackets.replace_literal (text, -1, 0, "&lt;");
                text = all_right_angular_brackets.replace_literal (text, -1, 0, "&gt;");
            } catch (RegexError e) {
                assert_not_reached ();
            }

            // If this is a git add -p hunk edit message, then we cannot
            // split at the first comment as the message starts with a comment.
            // Remove that comment and instead display that info in the instructions.
            if (is_add_p_hunk_edit_message) {
                text = text.substring (text.index_of ("\n")+1);
            }

            var first_comment_index = text.index_of ("#");

            message = text.slice (0, first_comment_index - 1);

            // Trim any newlines there may be at the end of the commit body
            while (message.length > 0 && message[message.length -1] == '\n') {
                message = message.slice (0, message.length - 1);
            }

            comment = text.slice (first_comment_index - 1, -1);

            // The commit message is always in the .git directory in the
            // project directory. Get the project directory’s name by using this.
            string project_directory_name;
            if (is_test) {
                project_directory_name = "test";
            } else {
                var path_components = new Gee.ArrayList<string>.wrap (commit_message_file_path.split ("/"));
                var project_directory_name_index = path_components.index_of (".git");
                if (project_directory_name_index > 0) {
                    project_directory_name = path_components[project_directory_name_index - 1];
                } else {
                    // Comet was launche with a reference to a file that’s not in a .git
                    // folder or our test folder. This shouldn’t happen but it’s not really an
                    // error so we’ll allow it with a warning.
                    warning (@"$(commit_message_file_path) is not a git commit message.");
                    project_directory_name = commit_message_file_path;
                }
            }

            // original_text.strip ().replace ("# ", "").replace("#\n", "\n").replace("#	", "  - ");
            return true;
        }
    }
}