
/******************************************************************************
* MODULE     : env.hpp
* DESCRIPTION: edit environment for typesetting
* COPYRIGHT  : (C) 1999  Joris van der Hoeven
*******************************************************************************
* This software falls under the GNU general public license and comes WITHOUT
* ANY WARRANTY WHATSOEVER. See the file $TEXMACS_PATH/LICENSE for more details.
* If you don't have this file, write to the Free Software Foundation, Inc.,
* 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
******************************************************************************/

#ifndef ENV_H
#define ENV_H
#include "vars.hpp"
#include "drd_info.hpp"
#include "font.hpp"
#include "language.hpp"
#include "path.hpp"
#include "hashmap.hpp"
#include "boxes.hpp"
#include "url.hpp"
#include "Graphics/frame.hpp"

#define DECORATION (-1)

/******************************************************************************
* The different types of system environment variables
******************************************************************************/

#define Env_User               0
#define Env_Fixed              1
#define Env_Magnification      2
#define Env_Language           3
#define Env_Mode               4
#define Env_Font               5
#define Env_Font_Size          6
#define Env_Index_Level        7
#define Env_Display_Style      8
#define Env_Math_Condensed     9
#define Env_Vertical_Pos      10
#define Env_Color             11
#define Env_Paragraph         12
#define Env_Page              13
#define Env_Preamble          14
#define Env_Frame             15
#define Env_Clipping          16
#define Env_Line_Width        17
#define Env_Grid              18
#define Env_Grid_Aspect       19
#define Env_Src_Style         20
#define Env_Src_Special       21
#define Env_Src_Compact       22
#define Env_Src_Close         23

/******************************************************************************
* For style file editing
******************************************************************************/

#define STYLE_ANGULAR         0
#define STYLE_SCHEME          1
#define STYLE_LATEX           2
#define STYLE_FUNCTIONAL      3

#define SPECIAL_RAW           0
#define SPECIAL_FORMAT        1
#define SPECIAL_NORMAL        2
#define SPECIAL_MAXIMAL       3

#define COMPACT_ALL           0
#define COMPACT_INLINE_ARGS   1
#define COMPACT_INLINE_START  2
#define COMPACT_INLINE        3
#define COMPACT_NONE          4

#define CLOSE_MINIMAL         0
#define CLOSE_COMPACT         1
#define CLOSE_LONG            2
#define CLOSE_REPEAT          3

#define INACTIVE_INLINE_RECURSE  0
#define INACTIVE_INLINE_ONCE     1
#define INACTIVE_INLINE_ERROR    2
#define INACTIVE_BLOCK_RECURSE   3
#define INACTIVE_BLOCK_ONCE      4
#define INACTIVE_BLOCK_ERROR     5

/******************************************************************************
* The edit environment
******************************************************************************/

class edit_env_rep: public concrete_struct {
public:
  display                      dis;
  drd_info&                    drd;
private:
  hashmap<string,tree>         env;
  hashmap<string,tree>         back;
public:
  hashmap<string,path>         src;
  list<hashmap<string,tree> >  macro_arg;
  list<hashmap<string,path> >  macro_src;
  array<box>                   decorated_boxes;

  hashmap<string,int>&         var_type;
  url                          base_file_name;
  hashmap<string,tree>&        local_ref;
  hashmap<string,tree>&        global_ref;
  hashmap<string,tree>&        local_aux;
  hashmap<string,tree>&        global_aux;
  bool                         complete;    // typeset complete document ?
  bool                         read_only;   // write-protected ?

  int       dpi;
  double    magn;
  double    flexibility;
  int       mode;
  language  lan;
  font      fn;
  int       fn_size;
  int       index_level;
  bool      display_style;
  bool      math_condensed;
  int       vert_pos;
  color     col;
  SI        lw;
  bool      preamble;
  frame     fr;
  point     clip_lim1;
  point     clip_lim2;
  int       src_style;
  int       src_special;
  int       src_compact;
  int       src_close;

  int       inactive_mode;

public:
  tree exec_extra_list (tree t, int pos);
  tree exec_extra_tuple (tree t, int pos);

private:
  tree exec_formatting (tree t, string v);
  void exec_until_formatting (tree t, path p, string v);
  bool exec_until_formatting (tree t, path p, string var, int l, string v);
  tree exec_table (tree t);
  void exec_until_table (tree t, path p);
  bool exec_until_table (tree t, path p, string var, int level);
  tree exec_assign (tree t);
  tree exec_with (tree t);
  void exec_until_with (tree t, path p);
  bool exec_until_with (tree t, path p, string var, int level);
  tree exec_drd_props (tree t);
  tree exec_provides (tree t);
  tree exec_value (tree t);
  tree exec_argument (tree t);
  bool exec_until_argument (tree t, path p, string var, int level);
  tree exec_get_label (tree t);
  tree exec_get_arity (tree t);
  tree exec_eval_args (tree t);
  tree exec_delay (tree t);
  tree exec_quasiquoted (tree t);
  tree exec_compound (tree t);
  void exec_until_compound (tree t, path p);
  bool exec_until_compound (tree t, path p, string var, int level);

  tree exec_or (tree t);
  tree exec_xor (tree t);
  tree exec_and (tree t);
  tree exec_not (tree t);
  tree exec_plus (tree t);
  tree exec_minus (tree t);
  tree exec_times (tree t);
  tree exec_over (tree t);
  tree exec_divide (tree t);
  tree exec_modulo (tree t);
  tree exec_merge (tree t);
  tree exec_length (tree t);
  tree exec_range (tree t);
  tree exec_number (tree t);
  tree exec_date (tree t);
  tree exec_translate (tree t);
  tree exec_find_file (tree t);
  tree exec_is_tuple (tree t);
  tree exec_lookup (tree t);
  tree exec_equal (tree t);
  tree exec_unequal (tree t);
  tree exec_less (tree t);
  tree exec_lesseq (tree t);
  tree exec_greater (tree t);
  tree exec_greatereq (tree t);
  tree exec_if (tree t);
  tree exec_case (tree t);
  tree exec_while (tree t);

  tree exec_point (tree t);

  tree exec_rewrite (tree t);
  bool exec_until_rewrite (tree t, path p, string var, int level);
  tree rewrite_inactive_arg (tree t, tree var, int i, bool bl, bool fl);
  tree rewrite_inactive_raw_data (tree t, tree var, bool block, bool flush);
  tree rewrite_inactive_document (tree t, tree var, bool block, bool flush);
  tree rewrite_inactive_concat (tree t, tree var, bool block, bool flush);
  tree rewrite_inactive_value (tree t, tree var, bool block, bool flush);
  tree rewrite_inactive_arg (tree t, tree var, bool block, bool flush);
  tree rewrite_inactive_active (tree t, tree var, bool block, bool flush);
  tree rewrite_inactive_var_active (tree t, tree var, bool block, bool flush);
  tree rewrite_inactive_symbol (tree t, tree var, bool block, bool flush);
  tree rewrite_inactive_hybrid (tree t, tree var, bool block, bool flush);
  tree rewrite_inactive_default (tree t, tree var, bool block, bool flush);
  tree rewrite_inactive (tree t, tree var, bool block, bool flush);
  tree rewrite_inactive (tree t, tree var);

public:
  edit_env_rep (display dis,
		drd_info& drd,
		url base_file_name,
		hashmap<string,tree>& local_ref,
		hashmap<string,tree>& global_ref,
		hashmap<string,tree>& local_aux,
		hashmap<string,tree>& global_aux);
  void   style_init_env ();

  /* execution of trees and setting environment variables */
  tree   exec (tree t);
  void   exec_until (tree t, path p);
  bool   exec_until (tree t, path p, string var, int level);
  string exec_string (tree t);        /* should be inline */
  tree   expand (tree t);
  bool   depends (tree t, string s, int level);
  tree   rewrite (tree t);

  inline void monitored_write (string s, tree t) {
    back->write_back (s, env); env (s)= t; }
  inline void monitored_write_update (string s, tree t) {
    back->write_back (s, env); env (s)= t; update (s); }
  inline void write (string s, tree t) { env (s)= t; }
  inline void write_update (string s, tree t) { env (s)= t; update (s); }
  inline tree local_begin (string s, tree t) {
    // tree r (env [s]); monitored_write_update (s, t); return r;
    tree& val= env (s); tree r (val); val= t; update (s); return r; }
  inline void local_end (string s, tree t) {
     env (s)= t; update (s); }
  inline tree local_begin_script () {
    return local_begin (MATH_LEVEL, as_string (index_level+1)); }
  inline void local_end_script (tree t) {
    local_end (MATH_LEVEL, t); }
  inline void assign (string s, tree t) {
    tree& val= env (s); t= exec(t); if (val != t) {
      back->write_back (s, env); val= t; update (s); } }
  inline bool provides (string s) { return env->contains (s); }
  inline tree read (string s) { return env [s]; }

  void write_default_env ();
  void write_env (hashmap<string,tree> user_env);
  void monitored_patch_env (hashmap<string,tree> patch);
  void patch_env (hashmap<string,tree> patch);
  void read_env (hashmap<string,tree>& ret);
  void local_start (hashmap<string,tree>& prev_back);
  void local_update (hashmap<string,tree>& oldpat, hashmap<string,tree>& chg);
  void local_end (hashmap<string,tree>& prev_back);

  /* updating environment variables */
  void   update_font ();
  void   update_color ();
  void   update_mode ();
  void   update_language ();
  void   update_frame ();
  void   update_clipping ();
  void   update_src_style ();
  void   update_src_special ();
  void   update_src_compact ();
  void   update_src_close ();
  void   update ();
  void   update (string env_var);

  /* miscellaneous and utilities */
  SI        decode_length (string l);
  point     decode_point (tree t);
  space     decode_space (string l);
  inline SI decode_length (tree l) { return decode_length (as_string (l)); }
  void      get_length_unit (string l, SI& un, string& un_str);
  string    add_lengths (string l1, string l2);
  string    multiply_length (double x, string l);
  bool      is_length (string s);
  double    divide_lengths (string l1, string l2);
  void      get_page_pars (SI& w, SI& h, SI& ww, SI& hh,
			   SI& odd, SI& even, SI& top, SI& bottom);

  /* retrieving environment variables */
  inline bool get_bool (string var) {
    tree t= env [var];
    if (is_compound (t)) return false;
    return as_bool (t->label); }
  inline int get_int (string var) {
    tree t= env [var];
    if (is_compound (t)) return 0;
    return as_int (t->label); }
  inline double get_double (string var) {
    tree t= env [var];
    if (is_compound (t)) return 0.0;
    return as_double (t->label); }
  inline string get_string (string var) {
    tree t= env [var];
    if (is_compound (t)) return "";
    return t->label; }
  inline SI get_length (string var) {
    tree t= env [var];
    if (is_compound (t)) return 0;
    return decode_length (t->label); }
  inline space get_space (string var) {
    tree t= env [var];
    if (is_compound (t)) return 0;
    return decode_space (t->label); }

  friend class edit_env;
  friend ostream& operator << (ostream& out, edit_env env);
};

class edit_env {
  CONCRETE(edit_env);
  edit_env (display dis,
	    drd_info& drd,
	    url base_file_name,
	    hashmap<string,tree>& local_ref,
	    hashmap<string,tree>& global_ref,
	    hashmap<string,tree>& local_aux,
	    hashmap<string,tree>& global_aux);
};
CONCRETE_CODE(edit_env);

void extract_format (tree fm, tree* r, int n);
tree load_inclusion (url u); // implented in tm_file.cpp

#endif // defined ENV_H
